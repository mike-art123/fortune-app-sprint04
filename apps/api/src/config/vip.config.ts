import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface VipPlan {
  id: 'monthly' | 'quarterly' | 'annual';
  titleFa: string;
  /** Price in Telegram Stars (XTR). */
  stars: number;
  /** Entitlement length in days. */
  days: number;
}

/**
 * VIP subscription plans paid with Telegram Stars. Star prices are env-tunable;
 * durations are fixed product decisions. No other currency exists in the app.
 */
@Injectable()
export class VipConfig {
  constructor(private readonly config: ConfigService) {}

  get plans(): VipPlan[] {
    return [
      {
        id: 'monthly',
        titleFa: 'عضویت یک‌ماهه',
        stars: this.config.get<number>('VIP_MONTHLY_STARS') ?? 250,
        days: 30,
      },
      {
        id: 'quarterly',
        titleFa: 'عضویت سه‌ماهه',
        stars: this.config.get<number>('VIP_QUARTERLY_STARS') ?? 600,
        days: 90,
      },
      {
        id: 'annual',
        titleFa: 'عضویت یک‌ساله',
        stars: this.config.get<number>('VIP_ANNUAL_STARS') ?? 2000,
        days: 365,
      },
    ];
  }

  planById(id: string): VipPlan | null {
    return this.plans.find((p) => p.id === id) ?? null;
  }
}
