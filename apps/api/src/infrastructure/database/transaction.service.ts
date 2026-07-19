import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from './prisma.service';

/** Transactional Prisma client passed into repositories. */
export type TransactionClient = Prisma.TransactionClient;

/**
 * Explicit transaction boundary (doc 52 §19). Future economic pipelines
 * (debit → reading → ledger → outbox) run inside `run` so they commit or roll
 * back atomically. Repositories accept the [TransactionClient].
 */
@Injectable()
export class TransactionService {
  constructor(private readonly prisma: PrismaService) {}

  run<T>(work: (tx: TransactionClient) => Promise<T>): Promise<T> {
    return this.prisma.$transaction(work, {
      isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
    });
  }
}
