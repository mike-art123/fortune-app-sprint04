import { Injectable } from '@nestjs/common';
import { dateKeyFor, nextResetAt } from '../../common/utils/daily-window.util';
import { MonetizationConfig } from '../../config/monetization.config';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/**
 * Free-daily allowance (coins removed): configured fortunes grant one free
 * successful reading per calendar day. The day boundary is computed on the
 * backend from the app timezone — never the device clock — and allowances are
 * independent per fortune: using the free Daily never touches the free Hafez.
 * The counter is only incremented AFTER a successful reading, so a failed
 * generation never burns the allowance.
 */
@Injectable()
export class FreeDailyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly monetization: MonetizationConfig,
  ) {}

  /** 1 when this fortune's free reading is still unused today, else 0. */
  async freeUsesRemainingToday(
    userId: string,
    fortuneId: string,
    now: Date = new Date(),
  ): Promise<number> {
    if (!this.monetization.isFreeDaily(fortuneId)) return 0;
    const dateKey = dateKeyFor(now, this.monetization.appTimezone);
    const row = await this.prisma.dailyFortuneUsage.findUnique({
      where: { userId_dateKey_fortuneId: { userId, dateKey, fortuneId } },
    });
    return row && row.successfulFreeUsageCount > 0 ? 0 : 1;
  }

  /** Count a successful free reading (call only after generation succeeded). */
  async consumeFreeToday(userId: string, fortuneId: string, now: Date = new Date()): Promise<void> {
    if (!this.monetization.isFreeDaily(fortuneId)) return;
    const dateKey = dateKeyFor(now, this.monetization.appTimezone);
    await this.prisma.dailyFortuneUsage.upsert({
      where: { userId_dateKey_fortuneId: { userId, dateKey, fortuneId } },
      create: {
        userId,
        dateKey,
        fortuneId,
        successfulFreeUsageCount: 1,
        lastFreeUsedAt: now,
      },
      update: {
        successfulFreeUsageCount: { increment: 1 },
        lastFreeUsedAt: now,
      },
    });
  }

  /** The exact instant today's allowance resets (backend-computed). */
  nextFreeResetAt(now: Date = new Date()): Date {
    return nextResetAt(now, this.monetization.appTimezone);
  }
}
