import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import type { Reading } from '@prisma/client';
import { DomainException } from '../../common/exceptions/domain.exception';
import { AppException } from '../../common/exceptions/app.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { nowIso, toIso } from '../../common/utils/date.util';
import { decodeCursor, encodeCursor } from '../../common/utils/pagination.util';
import { MonetizationConfig } from '../../config/monetization.config';
import { IdempotencyService } from '../../infrastructure/idempotency/idempotency.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { MediationService } from '../ads/mediation.service';
import { FreeDailyService } from '../entitlements/free-daily.service';
import { UsersService } from '../users/users.service';
import type { CreateReadingDto, ReadingInputDto } from './dto/create-reading.dto';
import { findFortune, type FortuneCatalogEntry } from './fortune-catalog';
import { READING_PROVIDER, type ReadingProvider } from './providers/reading-provider.interface';
import { ReadingsRepository } from './readings.repository';

export interface ReadingResponse {
  id: string;
  fortune: string;
  title: string;
  reading: string;
  createdAt: string;
}

export interface ReadingListPage {
  items: ReadingResponse[];
  /** Opaque cursor for the next page; null when this is the last page. */
  nextCursor: string | null;
}

/** How many rows a delete removed — 0 is a valid, quiet outcome. */
export interface DeleteResult {
  deleted: number;
}

/** One whispered intention, drawn from a reading's stored offering. */
export interface IntentionResponse {
  id: string;
  fortune: string;
  intention: string;
  createdAt: string;
}

const DEFAULT_PAGE_SIZE = 20;
const INTENTION_SCAN = 100;
const IDEMPOTENCY_OPERATION = 'reading.create';

type AccessMethod = 'free_daily' | 'rewarded_ad' | 'free';

/**
 * Orchestrates one reading (coins removed):
 * validate → access decision (free daily → ad entitlement) → generate →
 * persist → count. The free-daily allowance is counted only AFTER a successful
 * reading; a consumed ad entitlement is restored when generation fails, so the
 * user never re-watches an ad for a reading they did not receive.
 */
@Injectable()
export class ReadingsService {
  constructor(
    private readonly repository: ReadingsRepository,
    @Inject(READING_PROVIDER) private readonly provider: ReadingProvider,
    private readonly freeDaily: FreeDailyService,
    private readonly mediation: MediationService,
    private readonly monetization: MonetizationConfig,
    private readonly idempotency: IdempotencyService,
    private readonly users: UsersService,
    private readonly logger: AppLoggerService,
  ) {}

  async create(
    dto: CreateReadingDto,
    requestId: string | null,
    principal: AuthenticatedPrincipal,
    idempotencyKey: string | null,
  ): Promise<ReadingResponse> {
    const fortune = findFortune(dto.fortuneId);
    if (!fortune) {
      throw new DomainException('NOT_FOUND', 'این فال را نمی‌شناسیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    this.assertOfferingComplete(fortune, dto.input);

    const userId = principal.userId;

    if (idempotencyKey) {
      const replay = await this.idempotency.check({
        userId,
        operation: IDEMPOTENCY_OPERATION,
        key: idempotencyKey,
        payload: dto,
      });
      if (replay) {
        return JSON.parse(replay) as ReadingResponse;
      }
    }

    // ── access decision (spec order: free daily → rewarded ad) ──
    let accessMethod: AccessMethod = 'free';
    let consumedAdEntitlementId: string | null = null;

    const freeRemaining = await this.freeDaily.freeUsesRemainingToday(userId, fortune.id);
    if (freeRemaining > 0) {
      accessMethod = 'free_daily';
    } else if (dto.adEntitlementId) {
      await this.mediation.consumeEntitlement(userId, dto.adEntitlementId, fortune.id);
      consumedAdEntitlementId = dto.adEntitlementId;
      accessMethod = 'rewarded_ad';
    } else if (this.monetization.enforceAccessLimits) {
      throw new DomainException('ACCESS_REQUIRED', 'برای این فال، اول تبلیغ را ببین.', {
        status: HttpStatus.PAYMENT_REQUIRED,
      });
    }

    let record: Reading;
    try {
      // Personalization (scope §16): only a name the user confirmed in
      // onboarding is ever used; otherwise the reading stays impersonal.
      const owner = await this.users.findById(userId);
      const profile = {
        displayName: owner?.onboardingCompleted === true ? (owner.displayName ?? null) : null,
      };
      const generated = await this.provider.generate(fortune, dto.input, profile);
      record = await this.repository.create({
        userId,
        fortuneId: fortune.id,
        title: generated.title,
        content: generated.reading,
        inputJson: JSON.stringify(this.forStorage(dto.input)),
        requestId,
      });
    } catch (error) {
      // Retry entitlement: a verified ad reward survives a failed generation.
      await this.restoreAdEntitlement(consumedAdEntitlementId);
      if (error instanceof AppException) throw error;
      throw new DomainException('READING_FAILED', 'خوانش کامل نشد؛ دوباره تلاش کن.', {
        status: HttpStatus.BAD_GATEWAY,
        retryable: true,
        developerMessage: error instanceof Error ? error.message : String(error),
      });
    }

    // The free allowance is counted only after success, and a counting hiccup
    // must never take the reading away from the user.
    if (accessMethod === 'free_daily') {
      try {
        await this.freeDaily.consumeFreeToday(userId, fortune.id);
      } catch (countError) {
        this.logger.error('reading.freeDaily.count.failed', {
          userId,
          fortuneId: fortune.id,
          error: countError instanceof Error ? countError.message : String(countError),
        });
      }
    }

    const response = this.shape(record);

    if (idempotencyKey) {
      await this.idempotency.record({
        userId,
        operation: IDEMPOTENCY_OPERATION,
        key: idempotencyKey,
        payload: dto,
        result: JSON.stringify(response),
      });
    }

    return response;
  }

  /**
   * Newest-first history, scoped to the authenticated user. An invalid or
   * expired cursor is treated as "start from the top" rather than an error —
   * history is a calm surface and a stale cursor is not the user's fault.
   */
  async list(
    query: { limit?: number; cursor?: string },
    principal: AuthenticatedPrincipal,
  ): Promise<ReadingListPage> {
    const limit = query.limit ?? DEFAULT_PAGE_SIZE;
    const cursorId = decodeCursor(query.cursor);

    const rows = await this.repository.list({ userId: principal.userId, limit, cursorId });

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;

    const last = pageRows.at(-1);
    return {
      items: pageRows.map((row) => this.shape(row)),
      nextCursor: hasMore && last ? encodeCursor(last.id) : null,
    };
  }

  /** One reading by id — only ever the caller's own. */
  async getById(id: string, principal: AuthenticatedPrincipal): Promise<ReadingResponse> {
    const record = await this.repository.findById(id);
    if (!record || record.userId !== principal.userId) {
      throw new DomainException('NOT_FOUND', 'این خوانش را پیدا نکردیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }
    return this.shape(record);
  }

  /**
   * Erase the caller's whole history. Permanent, and only ever their own
   * rows. Returns how many readings were removed.
   */
  async clearHistory(principal: AuthenticatedPrincipal): Promise<DeleteResult> {
    const deleted = await this.repository.deleteAllForUser(principal.userId);
    this.logger.info('reading.history.cleared', { userId: principal.userId, deleted });
    return { deleted };
  }

  /**
   * Delete one reading the caller owns. An id that is unknown or belongs to
   * someone else removes nothing and reports zero — a quiet, idempotent
   * delete, never a way to probe another user's ids.
   */
  async deleteReading(id: string, principal: AuthenticatedPrincipal): Promise<DeleteResult> {
    const deleted = await this.repository.deleteOwned(id, principal.userId);
    return { deleted };
  }

  /** Give a consumed ad entitlement back; failures are logged, never thrown. */
  private async restoreAdEntitlement(entitlementId: string | null): Promise<void> {
    if (!entitlementId) return;
    try {
      await this.mediation.restoreEntitlement(entitlementId);
    } catch (restoreError) {
      this.logger.error('reading.adEntitlement.restore.failed', {
        entitlementId,
        error: restoreError instanceof Error ? restoreError.message : String(restoreError),
      });
    }
  }

  /** Single shaping point so create/list/get never drift apart. */
  private shape(record: Reading): ReadingResponse {
    return {
      id: record.id,
      fortune: record.fortuneId,
      title: record.title,
      reading: record.content,
      createdAt: record.createdAt ? toIso(record.createdAt) : nowIso(),
    };
  }

  /** The offering as stored. The cup photo (coffee) is read once by the
   *  provider and never persisted — privacy, and it would bloat every row. */
  private forStorage(input: ReadingInputDto): ReadingInputDto {
    if (input.imageDataUrl === undefined) return input;
    const stored: ReadingInputDto = { ...input };
    delete stored.imageDataUrl;
    return stored;
  }

  /** Gentle-but-firm server-side completeness checks (backend authority). */
  private assertOfferingComplete(fortune: FortuneCatalogEntry, input: ReadingInputDto): void {
    const invalid = (message: string): never => {
      throw new DomainException('VALIDATION_FAILED', message, {
        status: HttpStatus.BAD_REQUEST,
      });
    };

    switch (fortune.inputKind) {
      case 'intention':
        return; // silence is a valid offering
      case 'longText': {
        const words = (input.narration ?? '').trim().split(/\s+/).filter(Boolean).length;
        if (words < (fortune.minWords ?? 1)) {
          invalid('برای شروع، چند کلمه از خوابت کافی است.');
        }
        return;
      }
      case 'twoNames': {
        if (!input.selfName?.trim() || !input.otherName?.trim()) {
          invalid('برای دیدنِ سازگاری، هر دو نام لازم است.');
        }
        return;
      }
      case 'photo': {
        if (!input.imageDataUrl?.trim()) {
          invalid('برای فال قهوه، یک عکس از تهِ فنجان لازم است.');
        }
        return;
      }
    }
  }

  /** Save (bookmark) or unsave one reading the caller owns. Unknown or foreign
   *  ids change nothing and report saved:false — a quiet, idempotent toggle. */
  async setSaved(
    id: string,
    saved: boolean,
    principal: AuthenticatedPrincipal,
  ): Promise<{ saved: boolean }> {
    const changed = await this.repository.setSaved(id, principal.userId, saved);
    return { saved: saved && changed > 0 };
  }

  /** Newest-saved-first page of the caller's saved readings. */
  async listSaved(
    query: { limit?: number; cursor?: string },
    principal: AuthenticatedPrincipal,
  ): Promise<ReadingListPage> {
    const limit = query.limit ?? DEFAULT_PAGE_SIZE;
    const cursorId = decodeCursor(query.cursor);
    const rows = await this.repository.listSaved({
      userId: principal.userId,
      limit,
      cursorId,
    });
    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const last = pageRows.at(-1);
    return {
      items: pageRows.map((row) => this.shape(row)),
      nextCursor: hasMore && last ? encodeCursor(last.id) : null,
    };
  }

  /** The intentions the caller has whispered, newest first (capped). Silence
   *  is a valid offering, so readings without one are simply left out. */
  async listIntentions(principal: AuthenticatedPrincipal): Promise<{ items: IntentionResponse[] }> {
    const rows = await this.repository.recentForUser(principal.userId, INTENTION_SCAN);
    const out: IntentionResponse[] = [];
    for (const row of rows) {
      const intention = this.readIntention(row.inputJson);
      if (intention) {
        out.push({
          id: row.id,
          fortune: row.fortuneId,
          intention,
          createdAt: row.createdAt ? toIso(row.createdAt) : nowIso(),
        });
      }
    }
    return { items: out };
  }

  private readIntention(inputJson: string): string | null {
    try {
      const parsed = JSON.parse(inputJson) as { intention?: unknown };
      const value = typeof parsed.intention === 'string' ? parsed.intention.trim() : '';
      return value.length > 0 ? value : null;
    } catch {
      return null;
    }
  }
}
