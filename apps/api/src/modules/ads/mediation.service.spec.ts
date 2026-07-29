import { Prisma } from '@prisma/client';
import { MediationService } from './mediation.service';

const prisma = {
  adMediationSession: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  adProviderAttempt: {
    updateMany: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
  },
  rewardedAdEntitlement: {
    count: jest.fn(),
    create: jest.fn(),
    updateMany: jest.fn(),
  },
  user: {
    findUnique: jest.fn(),
  },
  $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
};

const ads = {
  providerOrder: ['adsgram', 'monetag'],
  isConfigured: (p: string) => p === 'adsgram' || p === 'monetag',
  clientConfigFor: (p: string) => (p === 'adsgram' ? { blockId: 'b1' } : { zoneId: 'z1' }),
  rewardSecretFor: (p: string) => (p === 'adsgram' ? 'secret-a' : 'secret-m'),
  loadTimeoutMs: 12000,
  verifyTimeoutMs: 20000,
  sessionTtlSeconds: 600,
  entitlementTtlSeconds: 1800,
  cooldownFailureThreshold: 3,
  cooldownWindowSeconds: 300,
  clientRewardEnabled: true,
};

const monetization = { appTimezone: 'UTC', rewardedAdsDailyLimit: 5 };

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

const service = new MediationService(
  prisma as never,
  ads as never,
  monetization as never,
  logger as never,
);

const NOW = new Date('2026-07-25T10:00:00Z');

function sessionRow(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: 'ses1',
    userId: 'u1',
    fortuneId: 'hafez',
    status: 'attempting',
    providerOrder: JSON.stringify(['adsgram', 'monetag']),
    currentProvider: 'adsgram',
    attemptCount: 1,
    idempotencyKey: 'key-12345678',
    expiresAt: new Date('2026-07-25T10:10:00Z'),
    attempts: [{ attemptNumber: 1, provider: 'adsgram', status: 'loading' }],
    ...overrides,
  };
}

type WriteArgs = { data: Record<string, unknown> };

function resetMocks(): void {
  jest.clearAllMocks();
  prisma.rewardedAdEntitlement.count.mockResolvedValue(0);
  prisma.adProviderAttempt.findMany.mockResolvedValue([]);
  prisma.adProviderAttempt.updateMany.mockResolvedValue({ count: 1 });
  prisma.adProviderAttempt.update.mockResolvedValue({});
  prisma.adMediationSession.findUnique.mockResolvedValue(null);
  prisma.adMediationSession.findFirst.mockResolvedValue(null);
  prisma.user.findUnique.mockResolvedValue(null);
  prisma.adMediationSession.create.mockImplementation((args: WriteArgs) =>
    Promise.resolve(sessionRow({ ...args.data, id: 'ses1', attempts: [] })),
  );
  prisma.adMediationSession.update.mockImplementation((args: WriteArgs) =>
    Promise.resolve(sessionRow({ ...args.data, attempts: [] })),
  );
  prisma.rewardedAdEntitlement.create.mockResolvedValue({ id: 'ent1' });
  prisma.rewardedAdEntitlement.updateMany.mockResolvedValue({ count: 1 });
}

describe('MediationService.completeByClient', () => {
  beforeEach(resetMocks);

  it('grants one entitlement for the caller attempting session', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(sessionRow({ entitlement: null }));

    const view = await service.completeByClient('u1', 'ses1', NOW);

    expect(view).toMatchObject({ status: 'rewarded', entitlementId: 'ent1' });
    expect(prisma.rewardedAdEntitlement.create).toHaveBeenCalledTimes(1);
    const createArg = prisma.rewardedAdEntitlement.create.mock.calls[0]?.[0] as WriteArgs;
    expect(createArg.data).toMatchObject({
      mediationSessionId: 'ses1',
      providerRewardId: 'ses1',
      provider: 'adsgram',
      status: 'available',
    });
  });

  it('is idempotent when the session is already rewarded', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(
      sessionRow({ status: 'rewarded', entitlement: { id: 'ent1', status: 'available' } }),
    );

    const view = await service.completeByClient('u1', 'ses1', NOW);

    expect(view).toMatchObject({ status: 'rewarded', entitlementId: 'ent1' });
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });

  it('returns the existing entitlement if the callback granted first', async () => {
    prisma.adMediationSession.findUnique
      .mockResolvedValueOnce(sessionRow({ entitlement: null }))
      .mockResolvedValueOnce(
        sessionRow({ status: 'rewarded', entitlement: { id: 'ent1', status: 'available' } }),
      );
    prisma.$transaction.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError('dup', {
        code: 'P2002',
        clientVersion: '5',
      }),
    );

    const view = await service.completeByClient('u1', 'ses1', NOW);

    expect(view).toMatchObject({ status: 'rewarded', entitlementId: 'ent1' });
    expect(prisma.rewardedAdEntitlement.create).toHaveBeenCalledTimes(1);
  });

  it('rejects a session that is not the caller own', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(
      sessionRow({ userId: 'someone-else', entitlement: null }),
    );

    await expect(service.completeByClient('u1', 'ses1', NOW)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });

  it('does not grant for an expired session', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(
      sessionRow({ expiresAt: new Date('2026-07-25T09:00:00Z'), entitlement: null }),
    );

    const view = await service.completeByClient('u1', 'ses1', NOW);

    expect(view.entitlementId).toBeNull();
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });

  it('falls back to a status read when client reward is disabled', async () => {
    const gated = new MediationService(
      prisma as never,
      { ...ads, clientRewardEnabled: false } as never,
      monetization as never,
      logger as never,
    );
    prisma.adMediationSession.findUnique.mockResolvedValue(
      sessionRow({ status: 'attempting', entitlement: null }),
    );

    const view = await gated.completeByClient('u1', 'ses1', NOW);

    expect(view.status).toBe('attempting');
    expect(view.entitlementId).toBeNull();
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });
});

describe('MediationService.createSession', () => {
  beforeEach(resetMocks);

  it('refuses when the global daily limit is exhausted', async () => {
    prisma.rewardedAdEntitlement.count.mockResolvedValue(5);

    await expect(
      service.createSession('u1', { fortuneId: 'hafez', idempotencyKey: 'key-12345678' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_LIMIT_REACHED' });
    expect(prisma.adMediationSession.create).not.toHaveBeenCalled();
  });

  it('replays an existing unexpired session for the same idempotency key', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(sessionRow());

    const view = await service.createSession(
      'u1',
      { fortuneId: 'hafez', idempotencyKey: 'key-12345678' },
      NOW,
    );

    expect(view.sessionId).toBe('ses1');
    expect(prisma.adMediationSession.create).not.toHaveBeenCalled();
  });

  it('starts with the first configured provider and hands its public config', async () => {
    const view = await service.createSession(
      'u1',
      { fortuneId: 'hafez', idempotencyKey: 'key-12345678' },
      NOW,
    );

    expect(view.status).toBe('attempting');
    expect(view.current?.provider).toBe('adsgram');
    expect(view.current?.clientConfig).toEqual({ blockId: 'b1' });
    expect(view.rewardedAdsRemainingToday).toBe(5);
  });

  it('rejects an unknown fortune', async () => {
    await expect(
      service.createSession('u1', { fortuneId: 'nope', idempotencyKey: 'key-12345678' }, NOW),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});

describe('MediationService.reportFailure', () => {
  beforeEach(resetMocks);

  it('falls through to the next provider on no_fill', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(sessionRow());

    await service.reportFailure('u1', 'ses1', { attemptNumber: 1, reason: 'no_fill' }, NOW);

    const updateArgs = prisma.adMediationSession.update.mock.calls[0]?.[0] as {
      data: Record<string, unknown>;
    };
    expect(updateArgs.data.currentProvider).toBe('monetag');
    expect(updateArgs.data.attemptCount).toBe(2);
  });

  it('exhausts the chain when the last provider fails with a fallback reason', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(
      sessionRow({ attemptCount: 2, currentProvider: 'monetag' }),
    );

    await service.reportFailure('u1', 'ses1', { attemptNumber: 2, reason: 'load_timeout' }, NOW);

    const updateArgs = prisma.adMediationSession.update.mock.calls[0]?.[0] as {
      data: Record<string, unknown>;
    };
    expect(updateArgs.data.status).toBe('exhausted');
  });

  it('does NOT fall through when the user skipped the ad', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(sessionRow());

    await service.reportFailure('u1', 'ses1', { attemptNumber: 1, reason: 'skipped' }, NOW);

    const updateArgs = prisma.adMediationSession.update.mock.calls[0]?.[0] as {
      data: Record<string, unknown>;
    };
    expect(updateArgs.data.status).toBe('failed');
    expect(updateArgs.data.currentProvider).toBeNull();
  });

  it('rejects a stale attempt number', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(sessionRow({ attemptCount: 2 }));

    await expect(
      service.reportFailure('u1', 'ses1', { attemptNumber: 1, reason: 'no_fill' }, NOW),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
  });
});

describe('MediationService.verifyRewardCallback', () => {
  beforeEach(resetMocks);

  function callbackSession(): Record<string, unknown> {
    return sessionRow({
      user: { telegramId: '42' },
      attempts: [{ attemptNumber: 1, provider: 'adsgram', status: 'shown' }],
    });
  }

  it('rejects a bad shared secret', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(callbackSession());

    await expect(
      service.verifyRewardCallback('adsgram', { sid: 'ses1', uid: '42', token: 'wrong' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });

  it('rejects a user mismatch', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(callbackSession());

    await expect(
      service.verifyRewardCallback('adsgram', { sid: 'ses1', uid: '99', token: 'secret-a' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
  });

  it('rejects an expired session', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue({
      ...callbackSession(),
      expiresAt: new Date('2026-07-25T09:00:00Z'),
    });

    await expect(
      service.verifyRewardCallback('adsgram', { sid: 'ses1', uid: '42', token: 'secret-a' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
  });

  it('issues exactly one entitlement on a valid callback', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(callbackSession());

    const res = await service.verifyRewardCallback(
      'adsgram',
      { sid: 'ses1', uid: '42', token: 'secret-a', reward: 'r-1' },
      NOW,
    );

    expect(res).toEqual({ ok: true });
    const createArgs = prisma.rewardedAdEntitlement.create.mock.calls[0]?.[0] as {
      data: Record<string, unknown>;
    };
    expect(createArgs.data.providerRewardId).toBe('r-1');
    expect(createArgs.data.status).toBe('available');
  });

  it('maps a duplicate reward to AD_VERIFICATION_FAILED (replay protection)', async () => {
    prisma.adMediationSession.findUnique.mockResolvedValue(callbackSession());
    prisma.$transaction.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError('dup', {
        code: 'P2002',
        clientVersion: '5',
      }),
    );

    await expect(
      service.verifyRewardCallback('adsgram', { sid: 'ses1', uid: '42', token: 'secret-a' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
  });

  // AdsGram's reward URL can only carry [userId] (the Telegram id), so the
  // callback arrives with no sid — the service must bind by the user's active
  // session on the provider instead.
  it('rewards the user active session on a userid-only (AdsGram) callback', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', telegramId: '42' });
    prisma.adMediationSession.findFirst.mockResolvedValue(callbackSession());

    const res = await service.verifyRewardCallback(
      'adsgram',
      { uid: '42', token: 'secret-a' },
      NOW,
    );

    expect(res).toEqual({ ok: true });
    // No provider reward id in the URL → the session id anchors replay safety.
    const createArgs = prisma.rewardedAdEntitlement.create.mock.calls[0]?.[0] as {
      data: Record<string, unknown>;
    };
    expect(createArgs.data.providerRewardId).toBe('ses1');
    expect(createArgs.data.status).toBe('available');
  });

  it('refuses a userid-only callback with no active session (post-reward replay)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', telegramId: '42' });
    prisma.adMediationSession.findFirst.mockResolvedValue(null);

    await expect(
      service.verifyRewardCallback('adsgram', { uid: '42', token: 'secret-a' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
    expect(prisma.rewardedAdEntitlement.create).not.toHaveBeenCalled();
  });

  it('refuses a userid-only callback for an unknown Telegram user', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(
      service.verifyRewardCallback('adsgram', { uid: '999', token: 'secret-a' }, NOW),
    ).rejects.toMatchObject({ code: 'AD_VERIFICATION_FAILED' });
  });
});

describe('MediationService entitlement consume/restore', () => {
  beforeEach(resetMocks);

  it('consumes an available entitlement once', async () => {
    await service.consumeEntitlement('u1', 'ent1', 'hafez', NOW);
    expect(prisma.rewardedAdEntitlement.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: 'ent1', userId: 'u1', status: 'available' }),
      }),
    );
  });

  it('throws when the entitlement is unavailable', async () => {
    prisma.rewardedAdEntitlement.updateMany.mockResolvedValue({ count: 0 });

    await expect(service.consumeEntitlement('u1', 'ent1', 'hafez', NOW)).rejects.toMatchObject({
      code: 'AD_VERIFICATION_FAILED',
    });
  });

  it('restores a consumed entitlement for retry after generation failure', async () => {
    await service.restoreEntitlement('ent1');
    expect(prisma.rewardedAdEntitlement.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'ent1', status: 'consumed' },
        data: { status: 'available', consumedAt: null },
      }),
    );
  });
});
