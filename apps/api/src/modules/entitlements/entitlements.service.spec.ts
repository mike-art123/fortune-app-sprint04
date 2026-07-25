import { EntitlementsService } from './entitlements.service';

const prisma = {
  subscription: {
    findUnique: jest.fn(),
    upsert: jest.fn(),
  },
};

const service = new EntitlementsService(prisma as never);

const NOW = new Date('2026-07-19T12:00:00Z');

describe('EntitlementsService.assessReading', () => {
  beforeEach(() => jest.clearAllMocks());

  it('grants free access when no subscription exists (coins removed)', async () => {
    prisma.subscription.findUnique.mockResolvedValue(null);

    const res = await service.assessReading('u1', NOW);

    expect(res).toEqual({ covered: true, source: 'free', cost: 0 });
  });

  it('covers the reading fully under an active, unexpired subscription', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      userId: 'u1',
      plan: 'monthly',
      status: 'active',
      currentPeriodEnd: new Date('2026-08-01T00:00:00Z'),
    });

    const res = await service.assessReading('u1', NOW);

    expect(res).toEqual({ covered: true, source: 'subscription', cost: 0 });
  });

  it('does not honor an expired subscription', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      userId: 'u1',
      plan: 'monthly',
      status: 'active',
      currentPeriodEnd: new Date('2026-07-01T00:00:00Z'),
    });

    const res = await service.assessReading('u1', NOW);

    expect(res.source).toBe('free');
    expect(res.cost).toBe(0);
  });

  it('does not honor a canceled subscription even inside its period', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      userId: 'u1',
      plan: 'monthly',
      status: 'canceled',
      currentPeriodEnd: new Date('2026-08-01T00:00:00Z'),
    });

    const res = await service.assessReading('u1', NOW);

    expect(res.source).toBe('free');
  });

  it('grantSubscription upserts an active subscription for the user', async () => {
    prisma.subscription.upsert.mockResolvedValue({ id: 's1' });
    const end = new Date('2026-08-19T00:00:00Z');

    await service.grantSubscription({ userId: 'u1', plan: 'monthly', currentPeriodEnd: end });

    expect(prisma.subscription.upsert).toHaveBeenCalledWith({
      where: { userId: 'u1' },
      create: { userId: 'u1', plan: 'monthly', status: 'active', currentPeriodEnd: end },
      update: { plan: 'monthly', status: 'active', currentPeriodEnd: end },
    });
  });
});
