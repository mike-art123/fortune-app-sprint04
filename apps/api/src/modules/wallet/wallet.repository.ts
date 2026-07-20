import { Injectable } from '@nestjs/common';
import type { CoinTransaction, Wallet } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import type { TransactionClient } from '../../infrastructure/database/transaction.service';

/**
 * Persistence boundary for the wallet ledger.
 *
 * Invariant enforced at this layer's call sites (service): the denormalized
 * `balance` column changes ONLY together with an appended CoinTransaction row,
 * inside one transaction. This repository therefore exposes no method that
 * touches balance without a matching ledger mutation in the same tx.
 */
@Injectable()
export class WalletRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: TransactionClient) {
    return tx ?? this.prisma;
  }

  findByUserId(userId: string, tx?: TransactionClient): Promise<Wallet | null> {
    return this.client(tx).wallet.findUnique({ where: { userId } });
  }

  /**
   * Creates the wallet together with its starter ledger row in one nested
   * write — atomic even outside an explicit transaction. The starter credit
   * is a REAL transaction, not a conjured balance.
   */
  createWithStarter(userId: string, starterCoins: number, tx?: TransactionClient): Promise<Wallet> {
    return this.client(tx).wallet.create({
      data: {
        userId,
        balance: starterCoins,
        transactions: {
          create: {
            amount: starterCoins,
            kind: 'starter',
            reason: 'اعتبار آغازین',
          },
        },
      },
    });
  }

  /**
   * Atomically decrements the balance IF it can afford the cost. Returns true
   * when a row was updated. The conditional update is the concurrency guard:
   * two racing debits cannot both pass a `balance >= cost` that only covers
   * one of them.
   */
  async decrementIfAffordable(
    walletId: string,
    cost: number,
    tx: TransactionClient,
  ): Promise<boolean> {
    const result = await tx.wallet.updateMany({
      where: { id: walletId, balance: { gte: cost } },
      data: { balance: { decrement: cost } },
    });
    return result.count === 1;
  }

  incrementBalance(walletId: string, amount: number, tx: TransactionClient): Promise<unknown> {
    return tx.wallet.update({
      where: { id: walletId },
      data: { balance: { increment: amount } },
    });
  }

  appendLedgerRow(
    row: {
      walletId: string;
      amount: number;
      kind: string;
      reason: string | null;
      refType: string | null;
      refId: string | null;
    },
    tx: TransactionClient,
  ): Promise<CoinTransaction> {
    return tx.coinTransaction.create({ data: row });
  }

  findTransactionById(id: string, tx?: TransactionClient): Promise<CoinTransaction | null> {
    return this.client(tx).coinTransaction.findUnique({ where: { id } });
  }

  findByKindAndRef(
    walletId: string,
    kind: string,
    refId: string,
    tx?: TransactionClient,
  ): Promise<CoinTransaction | null> {
    return this.client(tx).coinTransaction.findUnique({
      where: { walletId_kind_refId: { walletId, kind, refId } },
    });
  }

  listTransactions(
    walletId: string,
    limit: number,
    tx?: TransactionClient,
  ): Promise<CoinTransaction[]> {
    return this.client(tx).coinTransaction.findMany({
      where: { walletId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit,
    });
  }
}
