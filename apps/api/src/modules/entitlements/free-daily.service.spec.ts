import { FreeDailyService } from './free-daily.service';

const prisma = {
  dailyFortuneUsage: {
    findUnique: jest.fn(),
    upsert: jest.fn(),
  },
};

const monetization = {
  appTimezone: 'UTC',
  freeDailyFortuneIds: ['hafez', 'daily'],
  isFreeDaily: (id: string) => id === 'hafez' || id === 'daily',
};

const service = new FreeDailyService(prisma as never, monetization as never);

const NOW = new Date('2026-07-25T10:00:00Z');

describe('FreeDailyService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    prisma.dailyFortuneUsage.findUnique.mockResolvedValue(null);
    prisma.dailyFortuneUsage.upsert.mockResolvedValue({});
  });

  it('grants one free use when nothing was used today', async () => {
    await expect(service.freeUsesRemainingToday('u1', 'hafez', NOW)).resolves.toBe(1);
  });

  it('reports zero once today’s free reading was used', async () => {
    prisma.dailyFortuneUsage.findUnique.mockResolvedValue({ successfulFreeUsageCount: 1 });

    await expect(service.freeUsesRemainingToday('u1', 'hafez', NOW)).resolves.toBe(0);
  });

  it('non-free fortunes never expose an allowance', async () => {
    await expect(service.freeUsesRemainingToday('u1', 'tarot', NOW)).resolves.toBe(0);
    expect(prisma.dailyFortuneUsage.findUnique).not.toHaveBeenCalled();
  });

  it('allowances are independent per fortune (hafez vs daily)', async () => {
    prisma.dailyFortuneUsage.findUnique.mockImplementation(
      (args: { where: { userId_dateKey_fortuneId: { fortuneId: string } } }) => {
        const used = args.where.userId_dateKey_fortuneId.fortuneId === 'daily';
        return Promise.resolve(used ? { successfulFreeUsageCount: 1 } : null);
      },
    );

    await expect(service.freeUsesRemainingToday('u1', 'daily', NOW)).resolves.toBe(0);
    await expect(service.freeUsesRemainingToday('u1', 'hafez', NOW)).resolves.toBe(1);
  });

  it('consume writes the per-day bucket keyed by the app timezone', async () => {
    await service.consumeFreeToday('u1', 'hafez', NOW);

    const args = prisma.dailyFortuneUsage.upsert.mock.calls[0]?.[0] as {
      where: { userId_dateKey_fortuneId: { dateKey: string } };
    };
    expect(args.where.userId_dateKey_fortuneId.dateKey).toBe('2026-07-25');
  });

  it('consume is a no-op for non-free fortunes', async () => {
    await service.consumeFreeToday('u1', 'tarot', NOW);
    expect(prisma.dailyFortuneUsage.upsert).not.toHaveBeenCalled();
  });
});
