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

  /** Fortune ids that grant one free successful reading per calendar day. */
  get freeDailyFortuneIds(): string[] {
    const raw = this.config.get<string>('FREE_DAILY_FORTUNE_IDS') ?? 'hafez,daily';
    const ids = raw.split(',').map((id) => id.trim());
    return ids.filter((id) => id.length > 0);
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

  /** True when this fortune carries a free daily allowance. */
  isFreeDaily(fortuneId: string): boolean {
    return this.freeDailyFortuneIds.includes(fortuneId);
  }
}
