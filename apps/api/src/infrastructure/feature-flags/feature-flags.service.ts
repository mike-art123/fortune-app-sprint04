import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../cache/redis.service';

/**
 * Server-side feature flags (doc 52 §36): env defaults → database overrides,
 * cached briefly in Redis. Flags gate features; they never replace
 * authorization.
 */
@Injectable()
export class FeatureFlagsService {
  private static readonly CACHE_TTL_SECONDS = 30;

  /** Safe defaults — a missing flag never breaks a request. */
  private readonly defaults: Record<string, boolean> = {
    'system.maintenance-banner': false,
    // Guest (device-anchored) login for the Play build. Live by default so
    // the Android testers can sign in; a feature_flags row (enabled=false)
    // still force-closes it without a deploy, since rows win over defaults.
    'auth.guest': true,
    'hafez.raw-engine': true,
    'abjad.raw-engine': true,
    'tarot.raw-engine': true,
    'lenormand.raw-engine': true,
    'rune.raw-engine': true,
    'cards.raw-engine': true,
    'tasbih.raw-engine': true,
    'quran.raw-engine': true,
  };

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async isEnabled(flagKey: string): Promise<boolean> {
    const cacheKey = this.redis.key('feature-flags', flagKey, 'v1');
    try {
      const cached = await this.redis.getJson<boolean>(cacheKey);
      if (cached !== null) return cached;

      const row = await this.prisma.featureFlag.findUnique({ where: { key: flagKey } });
      const value = row?.enabled ?? this.defaults[flagKey] ?? false;
      await this.redis.setJson(cacheKey, value, FeatureFlagsService.CACHE_TTL_SECONDS);
      return value;
    } catch {
      // Infrastructure trouble degrades to defaults, never to a request failure.
      return this.defaults[flagKey] ?? false;
    }
  }
}
