import { createHash, timingSafeEqual } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { DomainException } from '../../common/exceptions/domain.exception';
import { nextResetAt } from '../../common/utils/daily-window.util';
import { AdsConfig } from '../../config/ads.config';
import { MonetizationConfig } from '../../config/monetization.config';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { findFortune } from '../readings/fortune-catalog';
import {
  ATTEMPT_STATUS,
  ENTITLEMENT_STATUS,
  SESSION_STATUS,
  isFallbackReason,
} from './ads.constants';
import { orderProviders, type ProviderHealth } from './provider-ordering';

export interface ProviderHandle {
  attemptNumber: number;
  provider: string;
  clientConfig: Record<string, string>;
  loadTimeoutMs: number;
  verifyTimeoutMs: number;
}

export interface MediationSessionView {
  sessionId: string;
  status: string;
  providerOrder: string[];
  current: ProviderHandle | null;
  rewardedAdsRemainingToday: number;
  expiresAt: string;
}

export interface MediationStatusView {
  sessionId: string;
  status: string;
  entitlementId: string | null;
  entitlementStatus: string | null;
}

/**
 * Backend-owned rewarded-ad mediation (coins removed). One session per pending
 * fortune request; the backend decides provider order, records every attempt,
 * falls through only on availability failures, and issues exactly ONE one-time
 * entitlement after a server-verified reward callback. The client never
 * decides rewards and never hardcodes a provider.
 */
@Injectable()
export class MediationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ads: AdsConfig,
    private readonly monetization: MonetizationConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async createSession(
    userId: string,
    input: { fortuneId: string; idempotencyKey: string },
    now: Date = new Date(),
  ): Promise<MediationSessionView> {
    if (!findFortune(input.fortuneId)) {
      throw new DomainException('NOT_FOUND', 'این فال را نمی‌شناسیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    const remaining = await this.rewardedAdsRemainingToday(userId, now);
    if (remaining <= 0) {
      throw new DomainException('AD_LIMIT_REACHED', 'سهمیه فال رایگان امروز تمام شده است.', {
        status: HttpStatus.TOO_MANY_REQUESTS,
      });
    }

    // Idempotent replay: the same pending request never spawns a second chain.
    const existing = await this.prisma.adMediationSession.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey: input.idempotencyKey } },
      include: { attempts: true },
    });
    if (existing && existing.expiresAt.getTime() > now.getTime()) {
      return this.sessionView(existing, existing.attempts, remaining);
    }

    const order = orderProviders(
      this.ads.providerOrder,
      (p) => this.ads.isConfigured(p),
      await this.recentHealth(now),
      this.ads.cooldownFailureThreshold,
    );

    const expiresAt = new Date(now.getTime() + this.ads.sessionTtlSeconds * 1000);

    if (order.length === 0) {
      const empty = await this.prisma.adMediationSession.create({
        data: {
          userId,
          fortuneId: input.fortuneId,
          status: SESSION_STATUS.exhausted,
          providerOrder: JSON.stringify([]),
          idempotencyKey: input.idempotencyKey,
          expiresAt,
        },
      });
      return this.sessionView(empty, [], remaining);
    }

    const first = order[0] as string;
    const session = await this.prisma.adMediationSession.create({
      data: {
        userId,
        fortuneId: input.fortuneId,
        status: SESSION_STATUS.attempting,
        providerOrder: JSON.stringify(order),
        currentProvider: first,
        attemptCount: 1,
        idempotencyKey: input.idempotencyKey,
        expiresAt,
        attempts: {
          create: { provider: first, attemptNumber: 1, status: ATTEMPT_STATUS.loading },
        },
      },
      include: { attempts: true },
    });
    return this.sessionView(session, session.attempts, remaining);
  }

  /**
   * Client-reported attempt outcome. Availability failures fall through to the
   * next provider automatically; user decisions (skip/cancel) and verification
   * failures stop the chain — exactly as specified.
   */
  async reportFailure(
    userId: string,
    sessionId: string,
    input: { attemptNumber: number; reason: string },
    now: Date = new Date(),
  ): Promise<MediationSessionView> {
    const session = await this.ownedActiveSession(userId, sessionId, now);
    if (input.attemptNumber !== session.attemptCount) {
      throw new DomainException('CONFLICT', 'این تلاش دیگر فعال نیست.', {
        status: HttpStatus.CONFLICT,
      });
    }

    const reason = input.reason;
    const fallback = isFallbackReason(reason);
    const userStopped = reason === 'skipped' || reason === 'cancelled';
    const attemptStatus = userStopped ? ATTEMPT_STATUS.skipped : ATTEMPT_STATUS.failed;

    await this.prisma.adProviderAttempt.updateMany({
      where: { mediationSessionId: session.id, attemptNumber: input.attemptNumber },
      data: { status: attemptStatus, failureReason: reason, completedAt: now },
    });

    const order = JSON.parse(session.providerOrder) as string[];
    const nextIndex = session.attemptCount; // attemptCount is 1-based
    const remaining = await this.rewardedAdsRemainingToday(userId, now);

    if (fallback && nextIndex < order.length) {
      const next = order[nextIndex] as string;
      const updated = await this.prisma.adMediationSession.update({
        where: { id: session.id },
        data: {
          attemptCount: session.attemptCount + 1,
          currentProvider: next,
          attempts: {
            create: {
              provider: next,
              attemptNumber: session.attemptCount + 1,
              status: ATTEMPT_STATUS.loading,
            },
          },
        },
        include: { attempts: true },
      });
      return this.sessionView(updated, updated.attempts, remaining);
    }

    let finalStatus: string = SESSION_STATUS.failed;
    if (fallback) finalStatus = SESSION_STATUS.exhausted;
    else if (reason === 'cancelled') finalStatus = SESSION_STATUS.cancelled;
    const done = await this.prisma.adMediationSession.update({
      where: { id: session.id },
      data: { status: finalStatus, currentProvider: null, completedAt: now },
      include: { attempts: true },
    });
    return this.sessionView(done, done.attempts, remaining);
  }

  async cancel(userId: string, sessionId: string, now: Date = new Date()): Promise<void> {
    const session = await this.ownedActiveSession(userId, sessionId, now);
    await this.prisma.adMediationSession.update({
      where: { id: session.id },
      data: { status: SESSION_STATUS.cancelled, currentProvider: null, completedAt: now },
    });
  }

  async getStatus(userId: string, sessionId: string): Promise<MediationStatusView> {
    const session = await this.prisma.adMediationSession.findUnique({
      where: { id: sessionId },
      include: { entitlement: true },
    });
    if (!session || session.userId !== userId) {
      throw new DomainException('NOT_FOUND', 'این جلسه را پیدا نکردیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }
    return {
      sessionId: session.id,
      status: session.status,
      entitlementId: session.entitlement?.id ?? null,
      entitlementStatus: session.entitlement?.status ?? null,
    };
  }

  /**
   * Client-completion reward. AdsGram's standard reward is the client-side
   * signal (the show() promise resolving); its server callback is an extra
   * layer AdsGram frames around ~50k DAU. So when the ad SDK reports the ad was
   * watched through, the client calls this and the reward is granted from that
   * signal, while the server callback stays untouched and, at scale, confirms
   * the same session.
   *
   * The two paths can never double-reward: they share one entitlement per
   * session (mediationSessionId unique), the (provider, providerRewardId)
   * unique key, and the attempting-to-rewarded flip. Whichever arrives first
   * grants; the other is a no-op. Behind AdsConfig.clientRewardEnabled
   * (default on) — off, this behaves like a status read and the client waits
   * for the callback.
   */
  async completeByClient(
    userId: string,
    sessionId: string,
    now: Date = new Date(),
  ): Promise<MediationStatusView> {
    if (!this.ads.clientRewardEnabled) {
      return this.getStatus(userId, sessionId);
    }

    const session = await this.prisma.adMediationSession.findUnique({
      where: { id: sessionId },
      include: { attempts: true, entitlement: true },
    });
    if (!session || session.userId !== userId) {
      throw new DomainException('NOT_FOUND', 'این جلسه را پیدا نکردیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    // Already rewarded (a prior completion, or the server callback beat us):
    // return the existing entitlement, never grant a second.
    if (session.status === SESSION_STATUS.rewarded) {
      return this.toStatusView(session);
    }

    // Only an unexpired, still-attempting session with a current provider can
    // reward; anything else is reported as-is (a raw path never guesses).
    const provider = session.currentProvider;
    if (
      session.status !== SESSION_STATUS.attempting ||
      session.expiresAt.getTime() <= now.getTime() ||
      !provider
    ) {
      return this.toStatusView(session);
    }

    const attempt = [...session.attempts]
      .filter((a) => a.provider === provider)
      .sort((a, b) => b.attemptNumber - a.attemptNumber)[0];
    if (!attempt) {
      return this.toStatusView(session);
    }

    const entitlementExpiry = new Date(now.getTime() + this.ads.entitlementTtlSeconds * 1000);

    try {
      const [entitlement] = await this.prisma.$transaction([
        this.prisma.rewardedAdEntitlement.create({
          data: {
            userId: session.userId,
            fortuneId: session.fortuneId,
            mediationSessionId: session.id,
            provider,
            providerRewardId: session.id,
            status: ENTITLEMENT_STATUS.available,
            expiresAt: entitlementExpiry,
          },
        }),
        this.prisma.adMediationSession.update({
          where: { id: session.id },
          data: { status: SESSION_STATUS.rewarded, completedAt: now },
        }),
        this.prisma.adProviderAttempt.update({
          where: {
            mediationSessionId_attemptNumber: {
              mediationSessionId: session.id,
              attemptNumber: attempt.attemptNumber,
            },
          },
          data: { status: ATTEMPT_STATUS.verified, verifiedAt: now, completedAt: now },
        }),
      ]);

      this.logger.info('ads.reward.client_completed', { provider, sessionId: session.id });
      return {
        sessionId: session.id,
        status: SESSION_STATUS.rewarded,
        entitlementId: entitlement.id,
        entitlementStatus: entitlement.status,
      };
    } catch (error) {
      // The server callback (or a parallel completion) granted first — the
      // shared unique keys collide. Return the entitlement that now exists.
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const rewarded = await this.prisma.adMediationSession.findUnique({
          where: { id: session.id },
          include: { entitlement: true },
        });
        if (rewarded) return this.toStatusView(rewarded);
      }
      throw error;
    }
  }

  private toStatusView(session: {
    id: string;
    status: string;
    entitlement: { id: string; status: string } | null;
  }): MediationStatusView {
    return {
      sessionId: session.id,
      status: session.status,
      entitlementId: session.entitlement?.id ?? null,
      entitlementStatus: session.entitlement?.status ?? null,
    };
  }

  /**
   * Provider server-to-server reward callback (the ONLY path that rewards).
   * Validates the shared secret, session binding, user binding and expiry;
   * the entitlement's unique keys make replays and double-rewards impossible.
   */
  async verifyRewardCallback(
    provider: string,
    params: { sid?: string; uid?: string; token?: string; reward?: string },
    now: Date = new Date(),
  ): Promise<{ ok: true }> {
    const secret = this.ads.rewardSecretFor(provider);
    if (secret.length === 0 || !this.safeEquals(params.token ?? '', secret)) {
      throw this.verificationFailed('bad token');
    }
    const session = await this.resolveRewardSession(provider, params, now);

    const attempt = [...session.attempts]
      .filter((a) => a.provider === provider)
      .sort((a, b) => b.attemptNumber - a.attemptNumber)[0];
    if (!attempt) throw this.verificationFailed('no attempt for provider');

    const rewardId = params.reward && params.reward.length > 0 ? params.reward : session.id;
    const entitlementExpiry = new Date(now.getTime() + this.ads.entitlementTtlSeconds * 1000);

    try {
      await this.prisma.$transaction([
        this.prisma.rewardedAdEntitlement.create({
          data: {
            userId: session.userId,
            fortuneId: session.fortuneId,
            mediationSessionId: session.id,
            provider,
            providerRewardId: rewardId,
            status: ENTITLEMENT_STATUS.available,
            expiresAt: entitlementExpiry,
          },
        }),
        this.prisma.adMediationSession.update({
          where: { id: session.id },
          data: { status: SESSION_STATUS.rewarded, completedAt: now },
        }),
        this.prisma.adProviderAttempt.update({
          where: {
            mediationSessionId_attemptNumber: {
              mediationSessionId: session.id,
              attemptNumber: attempt.attemptNumber,
            },
          },
          data: { status: ATTEMPT_STATUS.verified, verifiedAt: now, completedAt: now },
        }),
      ]);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw this.verificationFailed('replay detected');
      }
      throw error;
    }

    this.logger.info('ads.reward.verified', { provider, sessionId: session.id });
    return { ok: true };
  }

  /**
   * Resolve the session a reward callback belongs to. Providers that can echo
   * our session id (Monetag's `var3`) send `sid`. AdsGram's reward URL can only
   * carry `[userId]` (the Telegram id) — no session id — so when `sid` is
   * absent we bind to that user's single active `attempting` session on this
   * provider. Either way the session is verified rewardable (bound to the
   * caller's user, not expired, still attempting) before any reward is issued,
   * and the entitlement's unique keys keep double-rewards impossible.
   */
  private async resolveRewardSession(
    provider: string,
    params: { sid?: string; uid?: string },
    now: Date,
  ): Promise<{
    id: string;
    userId: string;
    fortuneId: string;
    status: string;
    expiresAt: Date;
    attempts: Array<{ attemptNumber: number; provider: string }>;
  }> {
    const sid = params.sid ?? '';
    const uid = params.uid ?? '';

    if (sid.length > 0) {
      const session = await this.prisma.adMediationSession.findUnique({
        where: { id: sid },
        include: { user: true, attempts: true },
      });
      if (!session) throw this.verificationFailed('unknown session');
      if (uid !== session.user.telegramId) throw this.verificationFailed('user mismatch');
      this.assertRewardable(session, now);
      return session;
    }

    // AdsGram: the reward URL delivers only `[userId]`. Bind to the user's one
    // active session on this provider; a second ping after the reward finds no
    // `attempting` session (it flipped to `rewarded`), so replays are refused.
    if (uid.length === 0) throw this.verificationFailed('missing user');
    const user = await this.prisma.user.findUnique({ where: { telegramId: uid } });
    if (!user) throw this.verificationFailed('unknown user');
    const session = await this.prisma.adMediationSession.findFirst({
      where: {
        userId: user.id,
        currentProvider: provider,
        status: SESSION_STATUS.attempting,
        expiresAt: { gt: now },
      },
      orderBy: { createdAt: 'desc' },
      include: { user: true, attempts: true },
    });
    if (!session) throw this.verificationFailed('no active session');
    return session;
  }

  private assertRewardable(session: { status: string; expiresAt: Date }, now: Date): void {
    if (session.expiresAt.getTime() <= now.getTime()) {
      throw this.verificationFailed('session expired');
    }
    if (session.status !== SESSION_STATUS.attempting) {
      throw this.verificationFailed(`session not attempting (${session.status})`);
    }
  }

  /** Atomically consume an available, unexpired entitlement for this fortune. */
  async consumeEntitlement(
    userId: string,
    entitlementId: string,
    fortuneId: string,
    now: Date = new Date(),
  ): Promise<void> {
    const consumed = await this.prisma.rewardedAdEntitlement.updateMany({
      where: {
        id: entitlementId,
        userId,
        fortuneId,
        status: ENTITLEMENT_STATUS.available,
        expiresAt: { gt: now },
      },
      data: { status: ENTITLEMENT_STATUS.consumed, consumedAt: now },
    });
    if (consumed.count === 0) {
      throw this.verificationFailed('entitlement unavailable');
    }
  }

  /** Retry entitlement: if generation fails after consumption, give it back. */
  async restoreEntitlement(entitlementId: string): Promise<void> {
    await this.prisma.rewardedAdEntitlement.updateMany({
      where: { id: entitlementId, status: ENTITLEMENT_STATUS.consumed },
      data: { status: ENTITLEMENT_STATUS.available, consumedAt: null },
    });
  }

  /** Global BakhtNegar daily allowance left (provider caps are separate). */
  async rewardedAdsRemainingToday(userId: string, now: Date = new Date()): Promise<number> {
    const dayStart = new Date(
      nextResetAt(now, this.monetization.appTimezone).getTime() - 24 * 3600 * 1000,
    );
    const used = await this.prisma.rewardedAdEntitlement.count({
      where: { userId, createdAt: { gte: dayStart } },
    });
    return Math.max(0, this.monetization.rewardedAdsDailyLimit - used);
  }

  // ── internals ──────────────────────────────────────────────────────────

  private async ownedActiveSession(
    userId: string,
    sessionId: string,
    now: Date,
  ): Promise<{
    id: string;
    userId: string;
    status: string;
    providerOrder: string;
    attemptCount: number;
    expiresAt: Date;
  }> {
    const session = await this.prisma.adMediationSession.findUnique({ where: { id: sessionId } });
    if (!session || session.userId !== userId) {
      throw new DomainException('NOT_FOUND', 'این جلسه را پیدا نکردیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }
    if (session.status !== SESSION_STATUS.attempting) {
      throw new DomainException('CONFLICT', 'این جلسه دیگر فعال نیست.', {
        status: HttpStatus.CONFLICT,
      });
    }
    if (session.expiresAt.getTime() <= now.getTime()) {
      throw new DomainException('CONFLICT', 'مهلت این جلسه تمام شده است.', {
        status: HttpStatus.CONFLICT,
      });
    }
    return session;
  }

  /** Recent consecutive fallback-failures per provider (global, windowed). */
  private async recentHealth(now: Date): Promise<ProviderHealth[]> {
    const windowStart = new Date(now.getTime() - this.ads.cooldownWindowSeconds * 1000);
    const health: ProviderHealth[] = [];
    for (const provider of this.ads.providerOrder) {
      const recent = await this.prisma.adProviderAttempt.findMany({
        where: { provider, startedAt: { gte: windowStart } },
        orderBy: { startedAt: 'desc' },
        take: this.ads.cooldownFailureThreshold,
        select: { status: true },
      });
      const allFailed =
        recent.length > 0 && recent.every((a) => a.status === ATTEMPT_STATUS.failed);
      health.push({ provider, recentConsecutiveFailures: allFailed ? recent.length : 0 });
    }
    return health;
  }

  private sessionView(
    session: {
      id: string;
      status: string;
      providerOrder: string;
      currentProvider: string | null;
      attemptCount: number;
      expiresAt: Date;
    },
    attempts: Array<{ attemptNumber: number; provider: string }>,
    remaining: number,
  ): MediationSessionView {
    const order = JSON.parse(session.providerOrder) as string[];
    let current: ProviderHandle | null = null;
    if (session.status === SESSION_STATUS.attempting && session.currentProvider) {
      current = {
        attemptNumber: session.attemptCount,
        provider: session.currentProvider,
        clientConfig: this.ads.clientConfigFor(session.currentProvider),
        loadTimeoutMs: this.ads.loadTimeoutMs,
        verifyTimeoutMs: this.ads.verifyTimeoutMs,
      };
    }
    return {
      sessionId: session.id,
      status: session.status,
      providerOrder: order,
      current,
      rewardedAdsRemainingToday: remaining,
      expiresAt: session.expiresAt.toISOString(),
    };
  }

  private verificationFailed(developerMessage: string): DomainException {
    return new DomainException('AD_VERIFICATION_FAILED', 'تأیید تبلیغ ناموفق بود.', {
      status: HttpStatus.FORBIDDEN,
      developerMessage,
    });
  }

  /** Constant-time comparison over sha256 digests (length-independent). */
  private safeEquals(a: string, b: string): boolean {
    const ha = createHash('sha256').update(a).digest();
    const hb = createHash('sha256').update(b).digest();
    return timingSafeEqual(ha, hb);
  }
}
