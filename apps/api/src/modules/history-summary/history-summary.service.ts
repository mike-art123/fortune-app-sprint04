import { Injectable } from '@nestjs/common';
import { AiConfig } from '../../config/ai.config';
import { MonetizationConfig } from '../../config/monetization.config';
import { extractJsonObject } from '../../common/json/extract-json-object';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { ReadingsRepository } from '../readings/readings.repository';
import { UsersService } from '../users/users.service';
import {
  RANGE_DAYS,
  buildDigest,
  digestFingerprint,
  type HistoryDigest,
  type SummaryRange,
} from './history-digest';
import { narrativeFrom, narrativeText, rangeLabelFa } from './history-narrative';
import { buildSummaryPrompt, summaryFrom } from './history-summary-prompt';

/** Off by default; turning it on is a deliberate, reversible decision. */
export const HISTORY_SUMMARY_FLAG = 'history.summary';

/** Two Persian sentences need very little room. */
const MAX_TOKENS = 200;

/** What the reader sees. `facts` is what the app counted; `summary` is how it
 * was said. `sourceIds` is the receipt: every reading behind the numbers. */
export interface HistorySummaryView {
  range: SummaryRange;
  rangeLabelFa: string;
  from: string;
  to: string;
  total: number;
  previousTotal: number;
  byFortune: HistoryDigest['byFortune'];
  facts: string[];
  summary: string;
  /** 'ai' when a model phrased it, 'rules' when the app did. */
  source: 'ai' | 'rules';
  sourceIds: string[];
}

/**
 * The reader's own history, said back to them (scope §6).
 *
 * Three rules hold this together. First, every number is computed by the
 * server from the reader's own readings — the model is only ever asked to
 * phrase them, and gets counts, never text. Second, the deterministic
 * sentences are always available, so a disabled flag, a missing key or a slow
 * upstream costs tone and nothing else. Third, the cache is keyed by what it
 * was built from, so adding or deleting a reading retires the old summary by
 * itself.
 */
@Injectable()
export class HistorySummaryService {
  constructor(
    private readonly readings: ReadingsRepository,
    private readonly users: UsersService,
    private readonly prisma: PrismaService,
    private readonly config: AiConfig,
    private readonly monetization: MonetizationConfig,
    private readonly flags: FeatureFlagsService,
    private readonly logger: AppLoggerService,
  ) {}

  async summarize(userId: string, range: SummaryRange): Promise<HistorySummaryView> {
    const now = new Date();
    const dayMs = 24 * 60 * 60 * 1000;
    // Two windows are needed to say "more than last time", so we read back
    // twice the range and nothing beyond it.
    const since = new Date(now.getTime() - 2 * RANGE_DAYS[range] * dayMs);
    const moments = await this.readings.listSince({ userId, since });

    const digest = buildDigest({
      moments,
      range,
      now,
      timeZone: this.monetization.appTimezone,
    });
    const facts = narrativeFrom(digest);
    const plain = narrativeText(digest);
    const fingerprint = digestFingerprint(digest);

    const phrased = await this.phrase(userId, digest, fingerprint);

    return {
      range,
      rangeLabelFa: rangeLabelFa(range),
      from: digest.from,
      to: digest.to,
      total: digest.total,
      previousTotal: digest.previousTotal,
      byFortune: digest.byFortune,
      facts,
      summary: phrased?.summary ?? plain,
      source: phrased ? 'ai' : 'rules',
      sourceIds: digest.sourceIds,
    };
  }

  /**
   * The warm sentence, if one is available and wanted. Returns null — meaning
   * "show the plain sentences" — whenever the flag is off, the reader asked
   * not to be profiled, there is nothing to describe, or the model is
   * unreachable or unconvincing.
   */
  private async phrase(
    userId: string,
    digest: HistoryDigest,
    fingerprint: string,
  ): Promise<{ summary: string } | null> {
    if (digest.total === 0) return null;

    const enabled = await this.flags.isEnabled(HISTORY_SUMMARY_FLAG);
    if (!enabled || !this.config.isConfigured) return null;

    // The same switch that silences suggestions also keeps this history off
    // the wire: nothing about this reader is sent anywhere.
    const profile = await this.users.getProfile(userId);
    if (profile.personalizationOptOut) return null;

    const cached = await this.cached(userId, digest.range, fingerprint);
    if (cached) return { summary: cached };

    const startedAt = Date.now();
    try {
      const raw = await this.ask(digest);
      const summary = summaryFrom(extractJsonObject(raw));
      if (summary === null) {
        this.logger.warn('history.summary.rejected', {
          range: digest.range,
          durationMs: Date.now() - startedAt,
        });
        return null;
      }
      await this.remember(userId, digest.range, fingerprint, summary);
      this.logger.info('history.summary.written', {
        range: digest.range,
        readings: digest.total,
        durationMs: Date.now() - startedAt,
      });
      return { summary };
    } catch (error) {
      // A summary is a courtesy. When it cannot be written, the plain
      // sentences are shown and nobody sees an error.
      this.logger.warn('history.summary.unavailable', {
        range: digest.range,
        durationMs: Date.now() - startedAt,
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return null;
    }
  }

  /** A hit only counts when it describes exactly today's readings. */
  private async cached(
    userId: string,
    range: SummaryRange,
    fingerprint: string,
  ): Promise<string | null> {
    try {
      const row = await this.prisma.aiSummaryCache.findUnique({
        where: { userId_rangeKey: { userId, rangeKey: range } },
      });
      return row && row.fingerprint === fingerprint ? row.summary : null;
    } catch {
      return null;
    }
  }

  private async remember(
    userId: string,
    range: SummaryRange,
    fingerprint: string,
    summary: string,
  ): Promise<void> {
    try {
      await this.prisma.aiSummaryCache.upsert({
        where: { userId_rangeKey: { userId, rangeKey: range } },
        create: { userId, rangeKey: range, fingerprint, summary, source: 'ai' },
        update: { fingerprint, summary, source: 'ai' },
      });
    } catch {
      // Failing to cache is not failing to answer.
    }
  }

  /** One bounded round-trip. No retries: nobody waits twice for a summary. */
  private async ask(digest: HistoryDigest): Promise<string> {
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
          temperature: 0.4,
          max_tokens: MAX_TOKENS,
          response_format: { type: 'json_object' },
          messages: buildSummaryPrompt(digest),
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
}
