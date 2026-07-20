import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import type { Reading } from '@prisma/client';
import { DomainException } from '../../common/exceptions/domain.exception';
import { AppException } from '../../common/exceptions/app.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { nowIso, toIso } from '../../common/utils/date.util';
import { decodeCursor, encodeCursor } from '../../common/utils/pagination.util';
import { IdempotencyService } from '../../infrastructure/idempotency/idempotency.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { EntitlementsService } from '../entitlements/entitlements.service';
import { WalletService } from '../wallet/wallet.service';
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

const DEFAULT_PAGE_SIZE = 20;
const IDEMPOTENCY_OPERATION = 'reading.create';

/**
 * Orchestrates one reading (Sprint 04 / doc 53):
 * validate → entitlement → atomic debit → generate → persist → shape.
 * If anything after a successful debit fails, the debit is refunded
 * (compensating ledger row, idempotent) before the error surfaces — the user
 * is never charged for a reading they did not receive.
 */
@Injectable()
export class ReadingsService {
  constructor(
    private readonly repository: ReadingsRepository,
    @Inject(READING_PROVIDER) private readonly provider: ReadingProvider,
    private readonly entitlements: EntitlementsService,
    private readonly wallet: WalletService,
    private readonly idempotency: IdempotencyService,
    private readonly logger: AppLoggerService,
  ) {}

  /**
   * Orchestrates a full paid-reading request: resolve the fortune, check
   * entitlement (subscription covers it, or debit the wallet), generate the
   * reading via the configured provider, then persist it. If generation or
   * persistence fails after a debit was taken, the debit is compensated
   * (refunded) before the error propagates — the caller never pays for a
   * reading they didn't receive.
   */
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

    const entitlement = await this.entitlements.assessReading(userId);

    let debitTransactionId: string | null = null;
    if (!entitlement.covered && entitlement.cost > 0) {
      const debit = await this.wallet.debitForReading({
        userId,
        cost: entitlement.cost,
        reason: `reading:${fortune.id}`,
        idempotencyRefId: idempotencyKey,
      });
      debitTransactionId = debit.transactionId;
    }

    let record: Reading;
    try {
      const generated = await this.provider.generate(fortune, dto.input);
      record = await this.repository.create({
        userId,
        fortuneId: fortune.id,
        title: generated.title,
        content: generated.reading,
        inputJson: JSON.stringify(dto.input),
        requestId,
      });
    } catch (error) {
      await this.compensate(debitTransactionId);
      if (error instanceof AppException) throw error;
      throw new DomainException('READING_FAILED', 'خوانش کامل نشد و سکه‌ای از تو کم نشد.', {
        status: HttpStatus.BAD_GATEWAY,
        retryable: true,
        developerMessage: error instanceof Error ? error.message : String(error),
      });
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

    return {
      items: pageRows.map((row) => this.shape(row)),
      nextCursor: hasMore ? encodeCursor(pageRows[pageRows.length - 1].id) : null,
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
   * Refund a charged-but-unfulfilled reading. Refund failures are logged and
   * swallowed so the original error surfaces; the ledger's uniqueness makes a
   * later manual/automated retry safe.
   */
  private async compensate(debitTransactionId: string | null): Promise<void> {
    if (!debitTransactionId) return;
    try {
      await this.wallet.refundDebit(debitTransactionId, 'reading:failed');
    } catch (refundError) {
      this.logger.error('reading.refund.failed', {
        debitTransactionId,
        error: refundError instanceof Error ? refundError.message : String(refundError),
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
    }
  }
}
