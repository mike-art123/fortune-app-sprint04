import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import type { AdminStatsService } from './admin-stats.service';
import { TelegramBotConfig } from './telegram-bot.config';
import { TelegramBotService } from './telegram-bot.service';
import type { TelegramUpdate } from './telegram-update.types';

function makeLogger(): AppLoggerService {
  return {
    debug: () => undefined,
    info: () => undefined,
    warn: () => undefined,
    error: () => undefined,
  } as unknown as AppLoggerService;
}

function makeConfig(overrides: Partial<TelegramBotConfig> = {}): TelegramBotConfig {
  const base = {
    botToken: '123:ABC',
    miniAppUrl: 'https://app.bakhtnegar.com',
    webhookPath: '/api/v1/telegram/webhook',
    publicBaseUrl: 'https://api.example.com',
    webhookUrl: 'https://api.example.com/api/v1/telegram/webhook',
    webhookSecret: 'secret123',
    adminTelegramIds: new Set<string>(),
  };
  return { ...base, ...overrides } as unknown as TelegramBotConfig;
}

function makeStats(message = 'STATS'): AdminStatsService {
  return { buildMessage: jest.fn().mockResolvedValue(message) } as unknown as AdminStatsService;
}

describe('TelegramBotService', () => {
  let fetchMock: jest.Mock;

  beforeEach(() => {
    fetchMock = jest.fn().mockResolvedValue({ json: () => Promise.resolve({ ok: true }) });
    globalThis.fetch = fetchMock as unknown as typeof fetch;
  });

  it('registers the menu button and the webhook on startup', async () => {
    const service = new TelegramBotService(makeConfig(), makeStats(), makeLogger());

    await service.onApplicationBootstrap();

    expect(fetchMock).toHaveBeenCalledTimes(2);

    // First the blue menu button, re-asserted so it can never go stale.
    const [menuUrl, menuInit] = fetchMock.mock.calls[0] as [string, { body: string }];
    expect(menuUrl).toBe('https://api.telegram.org/bot123:ABC/setChatMenuButton');
    const menuBody = JSON.parse(menuInit.body) as {
      menu_button: { type: string; text: string; web_app: { url: string } };
    };
    expect(menuBody.menu_button.type).toBe('web_app');
    expect(menuBody.menu_button.web_app.url).toBe('https://app.bakhtnegar.com');

    const [url, init] = fetchMock.mock.calls[1] as [string, { body: string }];
    expect(url).toBe('https://api.telegram.org/bot123:ABC/setWebhook');
    const body = JSON.parse(init.body) as Record<string, unknown>;
    expect(body.url).toBe('https://api.example.com/api/v1/telegram/webhook');
    expect(body.secret_token).toBe('secret123');
    expect(body.allowed_updates).toEqual(['message', 'pre_checkout_query']);
  });

  it('skips registration when no bot token is configured', async () => {
    const service = new TelegramBotService(
      makeConfig({ botToken: null } as Partial<TelegramBotConfig>),
      makeStats(),
      makeLogger(),
    );

    await service.onApplicationBootstrap();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('still refreshes the menu button when no public URL is available', async () => {
    const service = new TelegramBotService(
      makeConfig({ webhookUrl: null } as Partial<TelegramBotConfig>),
      makeStats(),
      makeLogger(),
    );

    await service.onApplicationBootstrap();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url] = fetchMock.mock.calls[0] as [string];
    expect(url).toBe('https://api.telegram.org/bot123:ABC/setChatMenuButton');
  });

  it('answers /start with a WebApp button to the Mini App', async () => {
    const service = new TelegramBotService(makeConfig(), makeStats(), makeLogger());
    const update: TelegramUpdate = {
      message: { text: '/start', chat: { id: 42 } },
    };

    await service.handleUpdate(update);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, { body: string }];
    expect(url).toBe('https://api.telegram.org/bot123:ABC/sendMessage');
    const body = JSON.parse(init.body) as {
      chat_id: number;
      reply_markup: { inline_keyboard: Array<Array<{ web_app: { url: string } }>> };
    };
    expect(body.chat_id).toBe(42);
    expect(body.reply_markup.inline_keyboard[0][0].web_app.url).toBe('https://app.bakhtnegar.com');
  });

  it('ignores messages that are not /start', async () => {
    const service = new TelegramBotService(makeConfig(), makeStats(), makeLogger());

    await service.handleUpdate({ message: { text: 'hello', chat: { id: 1 } } });

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('answers /stats for an allowlisted admin with the live numbers', async () => {
    const stats = makeStats('📊 آمار بخت‌نگار');
    const service = new TelegramBotService(
      makeConfig({ adminTelegramIds: new Set(['42']) } as Partial<TelegramBotConfig>),
      stats,
      makeLogger(),
    );

    await service.handleUpdate({
      message: { text: '/stats', chat: { id: 42 }, from: { id: 42 } },
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, { body: string }];
    expect(url).toBe('https://api.telegram.org/bot123:ABC/sendMessage');
    const body = JSON.parse(init.body) as { chat_id: number; text: string };
    expect(body.chat_id).toBe(42);
    expect(body.text).toContain('آمار');
  });

  it('stays silent on /stats from anyone not on the admin allowlist', async () => {
    const stats = makeStats();
    const service = new TelegramBotService(
      makeConfig({ adminTelegramIds: new Set(['42']) } as Partial<TelegramBotConfig>),
      stats,
      makeLogger(),
    );

    await service.handleUpdate({
      message: { text: '/stats', chat: { id: 999 }, from: { id: 999 } },
    });

    expect(fetchMock).not.toHaveBeenCalled();
    expect(stats.buildMessage as jest.Mock).not.toHaveBeenCalled();
  });

  it('validates the Telegram secret header', () => {
    const service = new TelegramBotService(
      makeConfig({ webhookSecret: 'abc' } as Partial<TelegramBotConfig>),
      makeStats(),
      makeLogger(),
    );

    expect(service.isValidSecret('abc')).toBe(true);
    expect(service.isValidSecret('nope')).toBe(false);
    expect(service.isValidSecret(undefined)).toBe(false);
  });
});
