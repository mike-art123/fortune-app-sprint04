import type { PrismaService } from '../../infrastructure/database/prisma.service';
import { AdminStatsService } from './admin-stats.service';

/**
 * The numbers are counted, never invented, and the message never carries a
 * single person's identity — only totals.
 */
function makePrisma(): PrismaService {
  return {
    user: {
      count: jest
        .fn()
        .mockResolvedValueOnce(160) // total
        .mockResolvedValueOnce(150) // telegram
        .mockResolvedValueOnce(4), // new today
    },
    reading: {
      count: jest.fn().mockResolvedValueOnce(500).mockResolvedValueOnce(30),
      groupBy: jest.fn().mockResolvedValue([
        { fortuneId: 'hafez', _count: { fortuneId: 300 } },
        { fortuneId: 'coffee', _count: { fortuneId: 120 } },
      ]),
    },
    rewardedAdEntitlement: {
      count: jest.fn().mockResolvedValueOnce(80).mockResolvedValueOnce(9),
    },
  } as unknown as PrismaService;
}

describe('AdminStatsService', () => {
  it('summarizes users, readings, ads and the top fortunes', async () => {
    const service = new AdminStatsService(makePrisma());

    const message = await service.buildMessage(new Date('2026-08-04T12:00:00.000Z'));

    expect(message).toContain('160'); // total users
    expect(message).toContain('تلگرام: 150');
    expect(message).toContain('مهمان: 10'); // 160 − 150, computed not queried
    expect(message).toContain('جدید امروز: 4');
    expect(message).toContain('فال‌ها: 500');
    expect(message).toContain('امروز: 30');
    expect(message).toContain('تبلیغ دیده‌شده: 80');
    expect(message).toContain('1. hafez — 300');
    // Nothing personal ever appears.
    expect(message).not.toMatch(/telegram_id|user_id|@/i);
  });
});
