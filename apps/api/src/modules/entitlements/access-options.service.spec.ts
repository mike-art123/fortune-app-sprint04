import { AccessOptionsService } from './access-options.service';

const entitlements = { hasActiveVip: jest.fn() };
const freeDaily = {
  freeUsesRemainingToday: jest.fn(),
  nextFreeResetAt: jest.fn(() => new Date('2026-07-25T20:30:00Z')),
};
const mediation = { rewardedAdsRemainingToday: jest.fn() };
const ads = {
  providerOrder: ['adsgram', 'monetag'],
  isConfigured: jest.fn(() => true),
};

const service = new AccessOptionsService(
  entitlements as never,
  freeDaily as never,
  mediation as never,
  ads as never,
);

const NOW = new Date('2026-07-25T10:00:00Z');

describe('AccessOptionsService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    entitlements.hasActiveVip.mockResolvedValue(false);
    freeDaily.freeUsesRemainingToday.mockResolvedValue(0);
    mediation.rewardedAdsRemainingToday.mockResolvedValue(5);
    ads.isConfigured.mockReturnValue(true);
  });

  it('VIP wins the decision order', async () => {
    entitlements.hasActiveVip.mockResolvedValue(true);
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);

    const view = await service.forFortune('u1', 'hafez', NOW);

    expect(view.accessState).toBe('vip');
    expect(view.isVip).toBe(true);
    expect(view.isFreeNow).toBe(false);
  });

  it('an unused free daily allowance starts immediately (no sheet)', async () => {
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);

    const view = await service.forFortune('u1', 'hafez', NOW);

    expect(view.accessState).toBe('free');
    expect(view.isFreeNow).toBe(true);
    expect(view.freeUsesRemainingToday).toBe(1);
    expect(view.nextFreeResetAt).toBe('2026-07-25T20:30:00.000Z');
  });

  it('otherwise offers the two-choice sheet when ads remain', async () => {
    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('choice');
    expect(view.rewardedAdAvailable).toBe(true);
  });

  it('falls to vip_only when the global ad limit is exhausted', async () => {
    mediation.rewardedAdsRemainingToday.mockResolvedValue(0);

    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('vip_only');
    expect(view.rewardedAdAvailable).toBe(false);
  });

  it('falls to vip_only when no ad provider is configured', async () => {
    ads.isConfigured.mockReturnValue(false);

    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('vip_only');
    expect(view.rewardedAdAvailable).toBe(false);
  });

  it('rejects an unknown fortune', async () => {
    await expect(service.forFortune('u1', 'nope', NOW)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('never exposes coin fields', async () => {
    const view = await service.forFortune('u1', 'hafez', NOW);

    expect(Object.keys(view)).toEqual([
      'fortuneId',
      'isVip',
      'isFreeNow',
      'freeUsesRemainingToday',
      'nextFreeResetAt',
      'rewardedAdAvailable',
      'rewardedAdsRemainingToday',
      'vipAvailable',
      'vipIncluded',
      'accessState',
    ]);
  });
});
