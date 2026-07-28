import { AccessOptionsService } from './access-options.service';

const freeDaily = {
  freeUsesRemainingToday: jest.fn(),
  nextFreeResetAt: jest.fn(() => new Date('2026-07-25T20:30:00Z')),
};
const mediation = { rewardedAdsRemainingToday: jest.fn() };
const ads = {
  providerOrder: ['adsgram', 'monetag'],
  isConfigured: jest.fn(() => true),
};

const service = new AccessOptionsService(freeDaily as never, mediation as never, ads as never);

const NOW = new Date('2026-07-25T10:00:00Z');

describe('AccessOptionsService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    freeDaily.freeUsesRemainingToday.mockResolvedValue(0);
    mediation.rewardedAdsRemainingToday.mockResolvedValue(5);
    ads.isConfigured.mockReturnValue(true);
  });

  it('an unused free daily allowance starts immediately (no ad)', async () => {
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);

    const view = await service.forFortune('u1', 'hafez', NOW);

    expect(view.accessState).toBe('free');
    expect(view.isFreeNow).toBe(true);
    expect(view.freeUsesRemainingToday).toBe(1);
    expect(view.nextFreeResetAt).toBe('2026-07-25T20:30:00.000Z');
  });

  it('requires a rewarded ad once the free allowance is spent', async () => {
    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('ad_required');
    expect(view.rewardedAdAvailable).toBe(true);
  });

  it('is unavailable when the global ad limit is exhausted', async () => {
    mediation.rewardedAdsRemainingToday.mockResolvedValue(0);

    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('unavailable');
    expect(view.rewardedAdAvailable).toBe(false);
  });

  it('is unavailable when no ad provider is configured', async () => {
    ads.isConfigured.mockReturnValue(false);

    const view = await service.forFortune('u1', 'tarot', NOW);

    expect(view.accessState).toBe('unavailable');
    expect(view.rewardedAdAvailable).toBe(false);
  });

  it('rejects an unknown fortune', async () => {
    await expect(service.forFortune('u1', 'nope', NOW)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('exposes only the ad/free access fields (no VIP, no coins)', async () => {
    const view = await service.forFortune('u1', 'hafez', NOW);

    expect(Object.keys(view)).toEqual([
      'fortuneId',
      'isFreeNow',
      'freeUsesRemainingToday',
      'nextFreeResetAt',
      'rewardedAdAvailable',
      'rewardedAdsRemainingToday',
      'accessState',
    ]);
  });
});
