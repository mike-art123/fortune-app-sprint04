import { Injectable } from '@nestjs/common';
import type { Subscription } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/**
 * Entitlements: decides whether THIS user may receive a reading right now.
 *
 * The coin economy has been removed. Access is never charged in coins — it is
 * free (VIP or free-daily/rewarded-ad in the new model). `assessReading` is the
 * single access authority; `cost` is retained only as a deprecated field that
 * is always 0 so existing callers keep compiling.
 */
export interface Entitlement {
  /** True when the user may receive the reading with no payment. */
  covered: boolean;
  source: 'subscription' | 'free' | null;
  /** Deprecated coin price — always 0 now that coins are removed. */
  cost: number;
}

@Injectable()
export class EntitlementsService {
  constructor(private readonly prisma: PrismaService) {}

  async assessReading(userId: string, now: Date = new Date()): Promise<Entitlement> {
    const subscription = await this.prisma.subscription.findUnique({ where: { userId } });
    if (this.isActive(subscription, now)) {
      return { covered: true, source: 'subscription', cost: 0 };
    }
    // Coins removed: readings are never debited. Access is free here; the
    // free-daily limit and rewarded-ad / VIP gating are layered on next via the
    // access-options flow. This method must never charge coins again.
    return { covered: true, source: 'free', cost: 0 };
  }

  /** True when the user holds an active, unexpired VIP subscription. */
  async hasActiveVip(userId: string, now: Date = new Date()): Promise<boolean> {
    const subscription = await this.prisma.subscription.findUnique({ where: { userId } });
    return this.isActive(subscription, now);
  }

  /**
   * System-level grant. There is intentionally no public purchase endpoint in
   * Sprint 04 — payments arrive with their own document; until then grants are
   * operational (support/admin) and test-driven.
   */
  grantSubscription(input: {
    userId: string;
    plan: string;
    currentPeriodEnd: Date;
  }): Promise<Subscription> {
    return this.prisma.subscription.upsert({
      where: { userId: input.userId },
      create: {
        userId: input.userId,
        plan: input.plan,
        status: 'active',
        currentPeriodEnd: input.currentPeriodEnd,
      },
      update: {
        plan: input.plan,
        status: 'active',
        currentPeriodEnd: input.currentPeriodEnd,
      },
    });
  }

  private isActive(subscription: Subscription | null, now: Date): boolean {
    return (
      subscription !== null &&
      subscription.status === 'active' &&
      subscription.currentPeriodEnd.getTime() > now.getTime()
    );
  }
}
