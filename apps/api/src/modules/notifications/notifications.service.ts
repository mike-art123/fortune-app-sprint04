import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { TelegramBotService } from '../telegram/telegram-bot.service';
import {
  DEFAULT_PREFERENCES,
  decideNotifications,
  localFields,
  type NotificationKind,
  type NotificationPreferenceView,
} from './notification-plan';
import { NotificationsConfig } from './notifications.config';

/** Off by default: nothing is ever sent until this is deliberately enabled. */
export const SMART_NOTIFICATIONS_FLAG = 'notifications.smart';

export interface NotificationPreferencePatch {
  dailyFortune?: boolean;
  streakReminder?: boolean;
  weeklySummary?: boolean;
  quietFromHour?: number;
  quietToHour?: number;
  dailyCap?: number;
  timeZone?: string;
  /** Hours of silence from now; 0 lifts the mute. */
  muteHours?: number;
}

export interface SweepResult {
  considered: number;
  sent: number;
  skipped: number;
}

/**
 * The columns an update may touch, as plain values. Declared here rather than
 * reaching for a generated Prisma input type so that one object can serve both
 * halves of the upsert without a cast.
 */
interface PreferenceWrite {
  dailyFortune?: boolean;
  streakReminder?: boolean;
  weeklySummary?: boolean;
  quietFromHour?: number;
  quietToHour?: number;
  dailyCap?: number;
  timeZone?: string;
  mutedUntil?: Date | null;
}

/**
 * Smart notifications (scope §7).
 *
 * The rules live in `notification-plan.ts` and are pure; everything here is the
 * plumbing around them: read what the reader agreed to, ask the rules what — if
 * anything — is worth saying, write the delivery row first, then send.
 *
 * Writing before sending is deliberate. The unique key on
 * `(user, kind, dateKey)` means a sweep that runs twice, or two sweeps racing,
 * cannot send the same message twice; the cost of that safety is that a failed
 * send is not retried today, which is the right trade for a courtesy message.
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly telegram: TelegramBotService,
    private readonly flags: FeatureFlagsService,
    private readonly config: NotificationsConfig,
    private readonly logger: AppLoggerService,
  ) {}

  /** What this reader agreed to. Absent means the modest defaults. */
  async preferences(userId: string): Promise<NotificationPreferenceView> {
    const row = await this.prisma.notificationPreference.findUnique({ where: { userId } });
    return row === null ? DEFAULT_PREFERENCES : this.view(row);
  }

  /**
   * Stores only what the caller mentioned. Hours and caps are clamped here as
   * well as validated at the edge — a preference that silences someone forever
   * by accident is worse than a rejected request.
   */
  async update(
    userId: string,
    patch: NotificationPreferencePatch,
  ): Promise<NotificationPreferenceView> {
    const data: PreferenceWrite = {};
    if (patch.dailyFortune !== undefined) data.dailyFortune = patch.dailyFortune;
    if (patch.streakReminder !== undefined) data.streakReminder = patch.streakReminder;
    if (patch.weeklySummary !== undefined) data.weeklySummary = patch.weeklySummary;
    if (patch.quietFromHour !== undefined) data.quietFromHour = clampHour(patch.quietFromHour);
    if (patch.quietToHour !== undefined) data.quietToHour = clampHour(patch.quietToHour);
    if (patch.dailyCap !== undefined) data.dailyCap = clampCap(patch.dailyCap);
    if (patch.timeZone !== undefined) data.timeZone = patch.timeZone;
    if (patch.muteHours !== undefined) {
      data.mutedUntil =
        patch.muteHours > 0 ? new Date(Date.now() + patch.muteHours * 60 * 60 * 1000) : null;
    }

    const row = await this.prisma.notificationPreference.upsert({
      where: { userId },
      create: { userId, ...data },
      update: data,
    });
    return this.view(row);
  }

  /**
   * One pass over a bounded batch of readers (scope §7). Driven by an external
   * scheduler, so no timer lives inside the API process.
   */
  async sweep(now = new Date()): Promise<SweepResult> {
    const enabled = await this.flags.isEnabled(SMART_NOTIFICATIONS_FLAG);
    if (!enabled) return { considered: 0, sent: 0, skipped: 0 };

    const users = await this.prisma.user.findMany({
      where: { onboardingCompleted: true },
      orderBy: { createdAt: 'asc' },
      take: this.config.sweepBatch,
      select: { id: true, telegramId: true, notificationPreference: true },
    });

    let sent = 0;
    let skipped = 0;

    for (const user of users) {
      const prefs = user.notificationPreference
        ? this.view(user.notificationPreference)
        : DEFAULT_PREFERENCES;
      const { dateKey } = localFields(now, prefs.timeZone);

      const [lastReading, sentToday] = await Promise.all([
        this.prisma.reading.findFirst({
          where: { userId: user.id },
          orderBy: { createdAt: 'desc' },
          select: { createdAt: true },
        }),
        this.prisma.notificationDelivery.findMany({
          where: { userId: user.id, dateKey },
          select: { kind: true },
        }),
      ]);

      const plans = decideNotifications({
        now,
        prefs,
        lastReadingAt: lastReading?.createdAt ?? null,
        sentToday: sentToday.map((row) => row.kind as NotificationKind),
      });

      if (plans.length === 0) {
        skipped++;
        continue;
      }

      for (const plan of plans) {
        const delivered = await this.deliver(user.id, user.telegramId, dateKey, plan);
        if (delivered) sent++;
      }
    }

    this.logger.info('notifications.sweep.done', {
      considered: users.length,
      sent,
      skipped,
    });
    return { considered: users.length, sent, skipped };
  }

  /**
   * Claim the slot, then send. A duplicate key means somebody else already
   * claimed it — which is the answer, not an error.
   */
  private async deliver(
    userId: string,
    telegramId: string,
    dateKey: string,
    plan: { kind: NotificationKind; text: string },
  ): Promise<boolean> {
    try {
      await this.prisma.notificationDelivery.create({
        data: { userId, kind: plan.kind, dateKey, status: 'sent' },
      });
    } catch {
      return false;
    }

    try {
      const response = await this.telegram.api('sendMessage', {
        chat_id: telegramId,
        text: plan.text,
      });
      if (!response.ok) {
        // The row stays: a Telegram refusal is not something to retry all day.
        this.logger.warn('notifications.send.refused', {
          kind: plan.kind,
          description: response.description ?? 'unknown',
        });
        return false;
      }
      // No name, no reading, no message text — the kind is the whole record.
      this.logger.info('notifications.sent', { kind: plan.kind });
      return true;
    } catch (error) {
      this.logger.warn('notifications.send.error', {
        kind: plan.kind,
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return false;
    }
  }

  private view(row: {
    dailyFortune: boolean;
    streakReminder: boolean;
    weeklySummary: boolean;
    quietFromHour: number;
    quietToHour: number;
    dailyCap: number;
    timeZone: string;
    mutedUntil: Date | null;
  }): NotificationPreferenceView {
    return {
      dailyFortune: row.dailyFortune,
      streakReminder: row.streakReminder,
      weeklySummary: row.weeklySummary,
      quietFromHour: row.quietFromHour,
      quietToHour: row.quietToHour,
      dailyCap: row.dailyCap,
      timeZone: row.timeZone,
      mutedUntil: row.mutedUntil === null ? null : row.mutedUntil.toISOString(),
    };
  }
}

function clampHour(value: number): number {
  return Math.min(23, Math.max(0, Math.trunc(value)));
}

function clampCap(value: number): number {
  return Math.min(5, Math.max(0, Math.trunc(value)));
}
