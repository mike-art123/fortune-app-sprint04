import { HttpStatus, Injectable } from '@nestjs/common';
import type { CoinTransaction, Wallet } from '@prisma/client';
import { WalletConfig } from '../../config/wallet.config';
import { DomainException } from '../../common/exceptions/domain.exception';
import { toIso } from '../../common/utils/date.util';
import { TransactionService } from '../../infrastructure/database/transaction.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { WalletRepository } from './wallet.repository';

export interface WalletTransactionResponse {
  id: string;
  amount: number;
  kind: string;
  reason: string | null;
  createdAt: string;
}

export interface WalletResponse {
  balance: number;
  transactions: WalletTransactionResponse[];
}

export interface DebitResult {
  transactionId: string;
  amount: number;
}

const RECENT_TRANSACTIONS = 20;

/** Unique-violation code raised when concurrent writes hit a unique key. */
const PRISMA_UNIQUE_VIOLATION = 'P2002';

/** Ledger row kinds. The ledger is truth; `balance` is its cache. */
const KIND_DEBIT = 'debit';
const KIND_REFUND = 'refund';

/** refType values tying ledger rows to their cause. */
const REF_IDEMPOTENCY = 'idempotency';
const REF_DEBIT = 'debit';

@Injectable()
export class WalletService {
  constructor(
    private readonly repository: WalletRepository,
    private readonly config: WalletConfig,
    private readonly transactions: TransactionService,
    private readonly logger: AppLoggerService,
  ) {}

  /**
   * Returns the wallet for this user, creating it (with its starter credit as
   * a real ledger row) on first sight.
   *
   * Concurrency: if two first-requests race, one create loses on the unique
   * userId constraint; we then read the winner's wallet instead of failing.
   * The user only ever sees one wallet and exactly one starter credit.
   */
  async getWalletForUser(userId: string): Promise<WalletResponse> {
    const wallet = await this.getOrCreate(userId);
    const transactions = await this.repository.listTransactions(wallet.id, RECENT_TRANSACTIONS);
    return this.shape(wallet, transactions);
  }

  /**
   * Atomic debit (Sprint 04 / doc 53): conditional decrement + appended ledger
   * row, one transaction. Fails with INSUFFICIENT_COINS when the balance
   * cannot afford the cost — the decrement and the ledger row then never
   * happen (or roll back together).
   *
   * Duplicate-charge defense in depth: when the caller passes the client's
   * Idempotency-Key, the debit row carries it as (walletId, 'debit', refId)
   * which is UNIQUE — even if the HTTP idempotency record was lost, a retry
   * cannot debit twice; it surfaces as DUPLICATE_REQUEST and rolls back.
   */
  async debitForReading(params: {
    userId: string;
    cost: number;
    reason: string;
    idempotencyRefId: string | null;
  }): Promise<DebitResult> {
    const { userId, cost, reason, idempotencyRefId } = params;
    if (!Number.isInteger(cost) || cost <= 0) {
      throw new DomainException('VALIDATION_FAILED', 'مبلغ برداشت معتبر نیست.', {
        status: HttpStatus.BAD_REQUEST,
        developerMessage: `invalid debit cost: ${cost}`,
      });
    }

    // The wallet is ensured OUTSIDE the debit transaction: a unique-violation
    // inside an open Postgres tx would abort it, and wallet creation is
    // already race-safe on its own (unique userId + winner re-read).
    const wallet = await this.getOrCreate(userId);

    return this.transactions.run(async (tx) => {
      const affordable = await this.repository.decrementIfAffordable(wallet.id, cost, tx);
      if (!affordable) {
        throw new DomainException('INSUFFICIENT_COINS', 'سکه‌هایت برای این خوانش کافی نیست.', {
          status: HttpStatus.PAYMENT_REQUIRED,
        });
      }

      try {
        const row = await this.repository.appendLedgerRow(
          {
            walletId: wallet.id,
            amount: -cost,
            kind: KIND_DEBIT,
            reason,
            refType: idempotencyRefId ? REF_IDEMPOTENCY : null,
            refId: idempotencyRefId,
          },
          tx,
        );
        return { transactionId: row.id, amount: row.amount };
      } catch (error) {
        if (this.isUniqueViolation(error)) {
          // Same Idempotency-Key already produced a debit: the whole tx
          // (including the decrement above) rolls back on this throw.
          throw new DomainException(
            'DUPLICATE_REQUEST',
            'این درخواست قبلاً ثبت شده است.',
            { status: HttpStatus.CONFLICT },
          );
        }
        throw error;
      }
    });
  }

  /**
   * Compensating refund of a debit (Sprint 04 / doc 53). Idempotent: the
   * refund row is unique per debit (walletId, 'refund', debitId) — a second
   * refund attempt returns the existing refund and changes no balance.
   */
  async refundDebit(debitTransactionId: string, reason: string): Promise<DebitResult> {
    return this.transactions.run(async (tx) => {
      const debit = await this.repository.findTransactionById(debitTransactionId, tx);
      if (!debit || debit.kind !== KIND_DEBIT || debit.amount >= 0) {
        throw new DomainException('CONFLICT', 'برگشت وجه ممکن نیست.', {
          status: HttpStatus.CONFLICT,
          developerMessage: `not a refundable debit: ${debitTransactionId}`,
        });
      }

      try {
        const refund = await this.repository.appendLedgerRow(
          {
            walletId: debit.walletId,
            amount: -debit.amount,
            kind: KIND_REFUND,
            reason,
            refType: REF_DEBIT,
            refId: debit.id,
          },
          tx,
        );
        await this.repository.incrementBalance(debit.walletId, -debit.amount, tx);
        this.logger.info('wallet.refunded', { debitId: debit.id, refundId: refund.id });
        return { transactionId: refund.id, amount: refund.amount };
      } catch (error) {
        if (this.isUniqueViolation(error)) {
          const existing = await this.repository.findByKindAndRef(
            debit.walletId,
            KIND_REFUND,
            debit.id,
            tx,
          );
          if (existing) {
            // Already refunded — idempotent success, no second credit.
            return { transactionId: existing.id, amount: existing.amount };
          }
        }
        throw error;
      }
    });
  }

  private async getOrCreate(userId: string): Promise<Wallet> {
    const existing = await this.repository.findByUserId(userId);
    if (existing) return existing;

    try {
      const created = await this.repository.createWithStarter(userId, this.config.starterCoins);
      this.logger.info('wallet.created', {
        walletId: created.id,
        starterCoins: this.config.starterCoins,
      });
      return created;
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        const winner = await this.repository.findByUserId(userId);
        if (winner) return winner;
      }
      throw error;
    }
  }

  private isUniqueViolation(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: unknown }).code === PRISMA_UNIQUE_VIOLATION
    );
  }

  private shape(wallet: Wallet, transactions: CoinTransaction[]): WalletResponse {
    return {
      balance: wallet.balance,
      transactions: transactions.map((t) => ({
        id: t.id,
        amount: t.amount,
        kind: t.kind,
        reason: t.reason,
        createdAt: toIso(t.createdAt),
      })),
    };
  }
}
