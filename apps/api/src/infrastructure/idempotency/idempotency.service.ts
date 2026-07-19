import { createHash } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../common/exceptions/domain.exception';
import { PrismaService } from '../database/prisma.service';

/**
 * Durable idempotency (doc 52 §30). Keys are scoped to user+operation. A
 * repeated identical request replays the stored result; a different payload
 * under the same key is rejected. Economic operations rely on this.
 */
@Injectable()
export class IdempotencyService {
  constructor(private readonly prisma: PrismaService) {}

  static fingerprint(payload: unknown): string {
    return createHash('sha256').update(JSON.stringify(payload ?? null)).digest('hex');
  }

  /**
   * Returns the stored result when the same request was already executed.
   * Returns null when the operation should proceed (and be recorded).
   */
  async check(scope: {
    userId: string;
    operation: string;
    key: string;
    payload: unknown;
  }): Promise<string | null> {
    const fingerprint = IdempotencyService.fingerprint(scope.payload);
    const existing = await this.prisma.idempotencyKey.findUnique({
      where: {
        userId_operation_key: { userId: scope.userId, operation: scope.operation, key: scope.key },
      },
    });
    if (!existing) return null;
    if (existing.fingerprint !== fingerprint) {
      throw new DomainException('DUPLICATE_REQUEST', 'این درخواست قبلاً با محتوای دیگری ثبت شده است.', {
        status: HttpStatus.CONFLICT,
      });
    }
    return existing.result;
  }

  async record(scope: {
    userId: string;
    operation: string;
    key: string;
    payload: unknown;
    result: string;
    ttlHours?: number;
  }): Promise<void> {
    const expiresAt = new Date(Date.now() + (scope.ttlHours ?? 24) * 3600 * 1000);
    await this.prisma.idempotencyKey.upsert({
      where: {
        userId_operation_key: { userId: scope.userId, operation: scope.operation, key: scope.key },
      },
      create: {
        userId: scope.userId,
        operation: scope.operation,
        key: scope.key,
        fingerprint: IdempotencyService.fingerprint(scope.payload),
        result: scope.result,
        expiresAt,
      },
      update: {},
    });
  }
}
