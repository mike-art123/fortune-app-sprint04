import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
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
    miniAppUrl: 'https://bakhtnegar.pages.dev',
    webhookPath: '/api/v1/telegram/webhook',
    publicBaseUrl: 'https://api.example.com',
    webhookUrl: 'https://api.example.com/api/v1/telegram/webhook',
    webhookSecret: 'secret123',
  };
  return { ...base, ...overrides } as unknown as TelegramBotConfig;
}

describe('TelegramBotService', () => {
  let fetchMock: jest.Mock;

  beforeEach(() => {
    fetchMock = jest.fn().mockResolvedValue({ json: () => Promise.resolve({ ok: true }) });
    globalThis.fetch = fetchMock as unknown as typeof fetch;
  });

  it('registers the webhook on startup with the public URL and secret', async () => {
    const service = new TelegramBotService(makeConfig(), makeLogger());

    await service.onApplicationBootstrap();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, { body: string }];
    expect(url).toBe('https://api.telegram.org/bot123:ABC/setWebhook');
    const body = JSON.parse(init.body) as Record<string, unknown>;
    expect(body.url).toBe('https://api.example.com/api/v1/telegram/webhook');
    expect(body.secret_token).toBe('secret123');
    expect(body.allowed_updates).toEqual(['message']);
  });

  it('skips registration when no bot token is configured', async () => {
    const service = new TelegramBotService(
      makeConfig({ botToken: null } as Partial<TelegramBotConfig>),
      makeLogger(),
    );

    await service.onApplicationBootstrap();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('skips registration when no public URL is available', async () => {
    const service = new TelegramBotService(
      makeConfig({ webhookUrl: null } as Partial<TelegramBotConfig>),
      makeLogger(),
    );

    await service.onApplicationBootstrap();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('answers /start with a WebApp button to the Mini App', async () => {
    const service = new TelegramBotService(makeConfig(), makeLogger());
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
    expect(body.reply_markup.inline_keyboard[0][0].web_app.url).toBe(
      'https://bakhtnegar.pages.dev',
    );
  });

  it('ignores messages that are not /start', async () => {
    const service = new TelegramBotService(makeConfig(), makeLogger());

    await service.handleUpdate({ message: { text: 'hello', chat: { id: 1 } } });

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('validates the Telegram secret header', () => {
    const service = new TelegramBotService(
      makeConfig({ webhookSecret: 'abc' } as Partial<TelegramBotConfig>),
      makeLogger(),
    );

    expect(service.isValidSecret('abc')).toBe(true);
    expect(service.isValidSecret('nope')).toBe(false);
    expect(service.isValidSecret(undefined)).toBe(false);
  });
});
