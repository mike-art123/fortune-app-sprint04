import type { PrismaService } from '../../infrastructure/database/prisma.service';
import type { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import type { TelegramBotService } from '../telegram/telegram-bot.service';
import { DEFAULT_PREFERENCES } from './notification-plan';
import type { NotificationsConfig } from './notifications.config';
import { NotificationsService } from './notifications.service';

const logger = {
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
} as unknown as AppLoggerService;

const config = {
  sweepSecret: 's',
  sweepBatch: 50,
  sweepBudgetMs: 60000,
} as unknown as NotificationsConfig;

function flags(enabled: boolean): FeatureFlagsService {
  return { isEnabled: jest.fn().mockResolvedValue(enabled) } as unknown as FeatureFlagsService;
}

function telegram(ok = true): { service: TelegramBotService; api: jest.Mock } {
  const api = jest.fn().mockResolvedValue({ ok });
  return { service: { api } as unknown as TelegramBotService, api };
}

interface DbOptions {
  preference?: Record<string, unknown> | null;
  lastReadingAt?: Date | null;
  sentToday?: Array<{ kind: string }>;
  claimFails?: boolean;
}

const STORED_ROW = {
  dailyFortune: true,
  streakReminder: true,
  weeklySummary: false,
  quietFromHour: 22,
  quietToHour: 8,
  dailyCap: 1,
  timeZone: 'Asia/Tehran',
  mutedUntil: null,
};

function db(options: DbOptions = {}): { service: PrismaService; created: jest.Mock } {
  const created = options.claimFails
    ? jest.fn().mockRejectedValue(new Error('duplicate key'))
    : jest.fn().mockResolvedValue({});
  const users = [
    { id: 'u1', telegramId: '4242', notificationPreference: options.preference ?? null },
  ];
  const lastReading = options.lastReadingAt ? { createdAt: options.lastReadingAt } : null;
  const stored = (args: { create: Record<string, unknown> }): Record<string, unknown> => ({
    ...STORED_ROW,
    ...args.create,
  });

  const service = {
    user: { findMany: jest.fn().mockResolvedValue(users) },
    reading: { findFirst: jest.fn().mockResolvedValue(lastReading) },
    notificationDelivery: {
      findMany: jest.fn().mockResolvedValue(options.sentToday ?? []),
      create: created,
    },
    notificationPreference: {
      findUnique: jest.fn().mockResolvedValue(options.preference ?? null),
      upsert: jest.fn().mockImplementation(stored),
    },
  } as unknown as PrismaService;
  return { service, created };
}

function build(overrides: { enabled?: boolean; db?: DbOptions; ok?: boolean } = {}): {
  service: NotificationsService;
  api: jest.Mock;
  created: jest.Mock;
  prisma: PrismaService;
} {
  const bot = telegram(overrides.ok ?? true);
  const store = db(overrides.db);
  const service = new NotificationsService(
    store.service,
    bot.service,
    flags(overrides.enabled ?? true),
    config,
    logger,
  );
  return { service, api: bot.api, created: store.created, prisma: store.service };
}

/** 10:00 in Tehran, well outside the default quiet hours. */
const MORNING = new Date('2026-07-26T06:30:00.000Z');

/**
 * The one feature that reaches somebody when they are not looking. Every test
 * here is about restraint: not sending, not sending twice, and never sending
 * anything that identifies the person it is about.
 */
describe('NotificationsService', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('sends nothing at all while the flag is off', async () => {
    const { service, api } = build({ enabled: false });
    await expect(service.sweep(MORNING)).resolves.toEqual({
      considered: 0,
      sent: 0,
      skipped: 0,
    });
    expect(api).not.toHaveBeenCalled();
  });

  it('sends what is due, through the bot, to the right chat', async () => {
    const { service, api } = build();
    await expect(service.sweep(MORNING)).resolves.toMatchObject({ sent: 1 });

    expect(api).toHaveBeenCalledTimes(1);
    const [method, body] = api.mock.calls[0] as [string, { chat_id: string; text: string }];
    expect(method).toBe('sendMessage');
    expect(body.chat_id).toBe('4242');
    expect(body.text).toContain('فال امروزت');
  });

  it('claims the slot before sending, so a second sweep is silent', async () => {
    const { service, api, created } = build({ db: { claimFails: true } });
    await expect(service.sweep(MORNING)).resolves.toMatchObject({ sent: 0 });

    expect(created).toHaveBeenCalledTimes(1);
    expect(api).not.toHaveBeenCalled();
  });

  it('respects a reader who has already heard from us today', async () => {
    const { service, api } = build({ db: { sentToday: [{ kind: 'dailyFortune' }] } });
    await expect(service.sweep(MORNING)).resolves.toMatchObject({ sent: 0, skipped: 1 });
    expect(api).not.toHaveBeenCalled();
  });

  it('stays quiet for a reader inside their own night', async () => {
    // Same instant, but this reader's quiet hours cover the whole morning.
    const { service, api } = build({
      db: { preference: { ...toRow(DEFAULT_PREFERENCES), quietFromHour: 9, quietToHour: 18 } },
    });
    await expect(service.sweep(MORNING)).resolves.toMatchObject({ sent: 0 });
    expect(api).not.toHaveBeenCalled();
  });

  it('keeps the row when Telegram refuses, rather than retrying all day', async () => {
    const { service, api, created } = build({ ok: false });
    await expect(service.sweep(MORNING)).resolves.toMatchObject({ sent: 0 });
    expect(created).toHaveBeenCalledTimes(1);
    expect(api).toHaveBeenCalledTimes(1);
  });

  it('reports the modest defaults for a reader who never chose', async () => {
    const { service } = build();
    await expect(service.preferences('u1')).resolves.toEqual(DEFAULT_PREFERENCES);
  });

  it('stores only what the caller mentioned, and clamps what it stores', async () => {
    const { service, prisma } = build();
    await service.update('u1', { quietFromHour: 99, dailyCap: 40, weeklySummary: true });

    const upsert = prisma.notificationPreference.upsert as unknown as jest.Mock;
    const args = upsert.mock.calls[0]?.[0] as { update: Record<string, unknown> };
    expect(args.update).toEqual({ quietFromHour: 23, dailyCap: 5, weeklySummary: true });
  });

  it('turns a mute into an end time, and zero back into silence lifted', async () => {
    const { service, prisma } = build();
    const upsert = prisma.notificationPreference.upsert as unknown as jest.Mock;

    await service.update('u1', { muteHours: 24 });
    const muted = (upsert.mock.calls[0]?.[0] as { update: { mutedUntil: Date } }).update;
    expect(muted.mutedUntil.getTime()).toBeGreaterThan(Date.now());

    await service.update('u1', { muteHours: 0 });
    const lifted = (upsert.mock.calls[1]?.[0] as { update: { mutedUntil: Date | null } }).update;
    expect(lifted.mutedUntil).toBeNull();
  });
});

/** The database row shape behind a preference view. */
function toRow(view: typeof DEFAULT_PREFERENCES): Record<string, unknown> {
  return { ...view, mutedUntil: null };
}
