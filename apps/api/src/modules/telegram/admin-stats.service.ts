import { Injectable } from '@nestjs/common';
import { nextResetAt } from '../../common/utils/daily-window.util';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/** The app's fixed day boundary for "today" buckets (matches notifications). */
const APP_TIMEZONE = 'Asia/Tehran';
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Live product numbers for the bot's admin `/stats` command. Strictly
 * read-only: every query counts rows, and only totals ever leave this
 * service — never a single person's id, name, or reading (privacy §16).
 */
@Injectable()
export class AdminStatsService {
  constructor(private readonly prisma: PrismaService) {}

  /** A ready-to-send Persian summary of the numbers that matter. */
  async buildMessage(now: Date): Promise<string> {
    const todayStart = new Date(nextResetAt(now, APP_TIMEZONE).getTime() - DAY_MS);
    const today = { createdAt: { gte: todayStart } };

    const [
      totalUsers,
      telegramUsers,
      newUsersToday,
      totalReadings,
      readingsToday,
      totalAds,
      adsToday,
      topFortunes,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { telegramId: { not: null } } }),
      this.prisma.user.count({ where: today }),
      this.prisma.reading.count(),
      this.prisma.reading.count({ where: today }),
      this.prisma.rewardedAdEntitlement.count(),
      this.prisma.rewardedAdEntitlement.count({ where: today }),
      this.prisma.reading.groupBy({
        by: ['fortuneId'],
        _count: { fortuneId: true },
        orderBy: { _count: { fortuneId: 'desc' } },
        take: 5,
      }),
    ]);

    const guestUsers = totalUsers - telegramUsers;
    const n = (v: number): string => v.toLocaleString('en-US');
    const top = topFortunes
      .map((row, i) => `${i + 1}. ${row.fortuneId} — ${n(row._count.fortuneId)}`)
      .join('\n');

    return [
      '📊 آمار بخت‌نگار',
      '',
      `👤 کاربرها: ${n(totalUsers)}`,
      `   ├ تلگرام: ${n(telegramUsers)}`,
      `   ├ مهمان: ${n(guestUsers)}`,
      `   └ جدید امروز: ${n(newUsersToday)}`,
      '',
      `🔮 فال‌ها: ${n(totalReadings)}  (امروز: ${n(readingsToday)})`,
      `🎬 تبلیغ دیده‌شده: ${n(totalAds)}  (امروز: ${n(adsToday)})`,
      '',
      '⭐ پرطرفدارترین فال‌ها:',
      top.length > 0 ? top : '—',
    ].join('\n');
  }
}
