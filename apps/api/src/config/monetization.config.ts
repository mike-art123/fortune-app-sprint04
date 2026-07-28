import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Access-model configuration (the coin economy is removed). Defines the app
 * timezone that anchors the daily free-allowance reset, which fortunes get a
 * free daily reading, the rewarded-ad daily cap, and whether access limits are
 * enforced yet. Never hardcoded in feature code; the daily boundary is computed
 * server-side from `appTimezone` and never from the device clock.
 */
@Injectable()
export class MonetizationConfig {
  constructor(private readonly config: ConfigService) {}

  /** IANA timezone that defines the free-allowance day boundary. */
  get appTimezone(): string {
    return this.config.get<string>('APP_TIMEZONE') ?? 'Asia/Tehran';
  }

  /**
   * Free-daily allowance per fortune, as `id:count` pairs. Hafez grants two free
   * successful readings per calendar day; every other fortune grants zero (a
   * rewarded ad unlocks each result). Tunable via FREE_DAILY_ALLOWANCES.
   */
  get freeDailyAllowances(): Map<string, number> {
    const raw = this.config.get<string>('FREE_DAILY_ALLOWANCES') ?? 'hafez:2';
    const out = new Map<string, number>();
    for (const pair of raw.split(',')) {
      const [id, count] = pair.split(':').map((part) => part.trim());
      const n = Number(count);
      if (id && Number.isInteger(n) && n > 0) out.set(id, n);
    }
    return out;
  }

  /** Maximum rewarded-ad unlocks per user per day. */
  get rewardedAdsDailyLimit(): number {
    return this.config.get<number>('REWARDED_ADS_DAILY_LIMIT') ?? 5;
  }

  /**
   * When false, access is not yet gated — readings stay free. This lets the
   * data model and access-options endpoint ship before the ad/VIP unlock paths
   * exist; flip to true only once the client sheet + Adsgram + Stars are live.
   */
  get enforceAccessLimits(): boolean {
    return this.config.get<boolean>('ENFORCE_ACCESS_LIMITS') ?? false;
  }

  /** Free successful readings allowed today for this fortune (0 = ad required). */
  freeDailyAllowance(fortuneId: string): number {
    return this.freeDailyAllowances.get(fortuneId) ?? 0;
  }
}
