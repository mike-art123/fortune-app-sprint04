import { Injectable } from '@nestjs/common';
import type { Subscription } from '@prisma/client';
import { WalletConfig } from '../../config/wallet.config';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/**
 * Entitlements (Sprint 04 / doc 53): decides what a reading costs THIS user
 * right now. An active, unexpired subscription covers readings entirely;
 * otherwise the backend-authoritative coin price applies. Feature code never
 * hardcodes economy values (§6).
 */
export interface Entitlement {
  /** True when no debit is needed (covered by subscription). */
  covered: boolean;
  source: 'subscription' | null;
  /** Coins to debit when not covered; 0 when covered. */
  cost: number;
}

@Injectable()
export class EntitlementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: WalletConfig,
  ) {}

  async assessReading(userId: string, now: Date = new Date()): Promise<Entitlement> {
    const subscription = await this.prisma.subscription.findUnique({ where: { userId } });
    if (this.isActive(subscription, now)) {
      return { covered: true, source: 'subscription', cost: 0 };
    }
    return { covered: false, source: null, cost: this.config.readingCostCoins };
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
