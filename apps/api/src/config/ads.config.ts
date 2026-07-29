import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Rewarded-ad mediation configuration. The backend owns provider priority and
 * all timing knobs; the client only executes what the backend hands it, so
 * provider order can change (per country/fill/revenue) without an app release.
 */
@Injectable()
export class AdsConfig {
  constructor(private readonly config: ConfigService) {}

  /** Ordered provider priority, e.g. ['adsgram', 'monetag']. */
  get providerOrder(): string[] {
    const raw = this.config.get<string>('REWARDED_AD_PROVIDERS') ?? 'adsgram,monetag';
    const ids = raw.split(',').map((p) => p.trim().toLowerCase());
    return ids.filter((p) => p.length > 0);
  }

  /** AdsGram block id (public client identifier). Empty = not configured. */
  get adsgramBlockId(): string {
    return this.config.get<string>('ADSGRAM_BLOCK_ID') ?? '';
  }

  /** Shared secret expected on the AdsGram server reward callback. */
  get adsgramRewardSecret(): string {
    return this.config.get<string>('ADSGRAM_REWARD_SECRET') ?? '';
  }

  /** Monetag zone id (public client identifier). Empty = not configured. */
  get monetagZoneId(): string {
    return this.config.get<string>('MONETAG_ZONE_ID') ?? '';
  }

  /** Shared secret expected on the Monetag S2S postback. */
  get monetagRewardSecret(): string {
    return this.config.get<string>('MONETAG_REWARD_SECRET') ?? '';
  }

  /** How long the client may wait for a provider to load an ad. */
  get loadTimeoutMs(): number {
    return this.config.get<number>('AD_LOAD_TIMEOUT_MS') ?? 12000;
  }

  /** How long the client may poll for server-side reward verification. */
  get verifyTimeoutMs(): number {
    return this.config.get<number>('AD_VERIFY_TIMEOUT_MS') ?? 20000;
  }

  /** Mediation-session lifetime; expired sessions can never reward. */
  get sessionTtlSeconds(): number {
    return this.config.get<number>('AD_SESSION_TTL_SECONDS') ?? 600;
  }

  /** Unlock lifetime after verification (retry entitlement window). */
  get entitlementTtlSeconds(): number {
    return this.config.get<number>('AD_ENTITLEMENT_TTL_SECONDS') ?? 1800;
  }

  /**
   * Grant the reward from the client's completion signal (AdsGram's standard
   * client-side callback), not only from the provider's server callback. On,
   * small publishers reward correctly; off falls back to the server callback
   * alone. Default on; set AD_CLIENT_REWARD_ENABLED=false to disable.
   */
  get clientRewardEnabled(): boolean {
    return this.config.get<string>('AD_CLIENT_REWARD_ENABLED') !== 'false';
  }

  /** Consecutive recent failures that demote a provider to the end. */
  get cooldownFailureThreshold(): number {
    return this.config.get<number>('AD_COOLDOWN_FAILURES') ?? 3;
  }

  /** Window (seconds) in which recent failures count toward cooldown. */
  get cooldownWindowSeconds(): number {
    return this.config.get<number>('AD_COOLDOWN_WINDOW_SECONDS') ?? 300;
  }

  /** True when this provider has the minimum config to be attempted. */
  isConfigured(provider: string): boolean {
    if (provider === 'adsgram') return this.adsgramBlockId.length > 0;
    if (provider === 'monetag') return this.monetagZoneId.length > 0;
    return false;
  }

  /** Public, client-safe config for one provider (never secrets). */
  clientConfigFor(provider: string): Record<string, string> {
    if (provider === 'adsgram') return { blockId: this.adsgramBlockId };
    if (provider === 'monetag') return { zoneId: this.monetagZoneId };
    return {};
  }

  /** Callback secret for one provider (server-side verification only). */
  rewardSecretFor(provider: string): string {
    if (provider === 'adsgram') return this.adsgramRewardSecret;
    if (provider === 'monetag') return this.monetagRewardSecret;
    return '';
  }
}
