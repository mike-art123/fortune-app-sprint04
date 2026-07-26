import { Injectable, NotFoundException } from '@nestjs/common';
import { AiConfig } from '../../config/ai.config';
import { extractJsonObject } from '../../common/json/extract-json-object';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import {
  FEELING_FA,
  isTender,
  promptFor,
  promptFrom,
  type Feeling,
  type ReflectionPrompt,
} from './reflection-feelings';
import { buildReflectionPrompt } from './reflection-prompt';

/** Off by default; the written questions are the floor, not the fallback. */
export const REFLECTION_JOURNAL_FLAG = 'reflection.journal';

/** A question needs very few tokens. */
const MAX_TOKENS = 60;

/** The stored row, as this service reads it. */
interface ReflectionRow {
  id: string;
  readingId: string | null;
  feeling: string;
  note: string;
  createdAt: Date;
  updatedAt: Date;
}

/** One entry, as its own author sees it. */
export interface ReflectionView {
  id: string;
  readingId: string | null;
  feeling: Feeling;
  feelingFa: string;
  note: string;
  createdAt: string;
  updatedAt: string;
}

export interface ReflectionPage {
  items: ReflectionView[];
  nextCursor: string | null;
}

/**
 * The reflection journal (scope §8).
 *
 * One rule governs this service: the note is never input to anything. It is not
 * summarised, not classified, not counted, never put in a prompt and never
 * logged — not even its length. The only thing that ever leaves this table is a
 * page of entries, going back to the person who wrote them.
 */
@Injectable()
export class ReflectionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: AiConfig,
    private readonly flags: FeatureFlagsService,
    private readonly logger: AppLoggerService,
  ) {}

  /** Newest first, with an opaque cursor — the same shape as history. */
  async list(userId: string, limit: number, cursorId?: string): Promise<ReflectionPage> {
    const rows = await this.prisma.reflectionEntry.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    });

    const page = rows.slice(0, limit);
    return {
      items: page.map((row) => this.view(row)),
      nextCursor: rows.length > limit ? (page[page.length - 1]?.id ?? null) : null,
    };
  }

  /** The reflection attached to one reading, if this person wrote one. */
  async forReading(userId: string, readingId: string): Promise<ReflectionView | null> {
    const row = await this.prisma.reflectionEntry.findFirst({
      where: { userId, readingId },
    });
    return row === null ? null : this.view(row);
  }

  /**
   * Writes or rewrites the entry for a reading. Idempotent by design: coming
   * back to the same reading edits what is there instead of stacking copies.
   */
  async save(
    userId: string,
    input: { readingId: string | null; feeling: Feeling; note: string },
  ): Promise<ReflectionView> {
    const data = { feeling: input.feeling, note: input.note.trim() };
    const existingId = await this.existingId(userId, input.readingId);

    if (existingId !== null) {
      const rewritten = await this.prisma.reflectionEntry.update({
        where: { id: existingId },
        data,
      });
      return this.saved(rewritten, input.feeling);
    }

    const written = await this.prisma.reflectionEntry.create({
      data: { userId, readingId: input.readingId, ...data },
    });
    return this.saved(written, input.feeling);
  }

  /** The id of the entry already on this reading, if there is one. */
  private async existingId(userId: string, readingId: string | null): Promise<string | null> {
    if (readingId === null) return null;
    const row = await this.prisma.reflectionEntry.findFirst({
      where: { userId, readingId },
      select: { id: true },
    });
    return row?.id ?? null;
  }

  /** One place to record the word and hand the entry back. */
  private saved(row: ReflectionRow, feeling: Feeling): ReflectionView {
    // The feeling is one of five words the app offered; the note is not here.
    this.logger.info('reflection.saved', { feeling });
    return this.view(row);
  }

  /** Deleting is immediate and total — it is their diary. */
  async remove(userId: string, id: string): Promise<void> {
    const deleted = await this.prisma.reflectionEntry.deleteMany({
      where: { id, userId },
    });
    if (deleted.count === 0) throw new NotFoundException('reflection not found');
  }

  /**
   * The line to sit under the note (scope §8). A heavier feeling is never
   * probed and never handed to a model: it is met with room, and with the plain
   * fact that talking to someone real is allowed.
   */
  async prompt(feeling: Feeling): Promise<ReflectionPrompt> {
    const written = promptFor(feeling);
    if (isTender(feeling)) return written;

    const enabled = await this.flags.isEnabled(REFLECTION_JOURNAL_FLAG);
    if (!enabled || !this.config.isConfigured) return written;

    try {
      const raw = await this.ask(feeling);
      const question = promptFrom(extractJsonObject(raw), feeling);
      if (question === null) return written;
      return { feeling, text: question, tender: false };
    } catch (error) {
      this.logger.warn('reflection.prompt.unavailable', {
        feeling,
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return written;
    }
  }

  /** One bounded round-trip. No retries: nobody waits twice for a question. */
  private async ask(feeling: Feeling): Promise<string> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const response = await fetch(`${this.config.baseUrl.replace(/\/+$/, '')}/chat/completions`, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.model,
          temperature: 0.5,
          max_tokens: MAX_TOKENS,
          response_format: { type: 'json_object' },
          messages: buildReflectionPrompt(feeling),
        }),
      });

      if (!response.ok) {
        throw new Error(`upstream responded ${response.status}`);
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) throw new Error('upstream returned an empty completion');
      return content;
    } finally {
      clearTimeout(timer);
    }
  }

  private view(row: ReflectionRow): ReflectionView {
    const feeling = row.feeling as Feeling;
    return {
      id: row.id,
      readingId: row.readingId,
      feeling,
      feelingFa: FEELING_FA[feeling] ?? row.feeling,
      note: row.note,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}
