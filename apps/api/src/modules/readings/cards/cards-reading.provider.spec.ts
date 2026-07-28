import { CardsReadingProvider, parseCardsReading } from './cards-reading.provider';
import { findFortune } from '../fortune-catalog';
import type { AiConfig } from '../../../config/ai.config';
import type { MonetizationConfig } from '../../../config/monetization.config';
import type { FeatureFlagsService } from '../../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { GeneratedReading, ReadingProvider } from '../providers/reading-provider.interface';

const cards = findFortune('cards')!;
const abjad = findFortune('abjad')!;

function makeFlags(enabled: boolean): FeatureFlagsService {
  return { isEnabled: jest.fn().mockResolvedValue(enabled) } as unknown as FeatureFlagsService;
}

function makeConfig(overrides: Partial<AiConfig> = {}): AiConfig {
  return {
    baseUrl: 'https://proxy.example.com/v1',
    apiKey: 'test-key',
    model: 'gpt-4o-mini',
    timeoutMs: 50,
    maxRetries: 0,
    isConfigured: true,
    ...overrides,
  } as AiConfig;
}

const monetization = { appTimezone: 'Asia/Tehran' } as unknown as MonetizationConfig;

type SpyLogger = AppLoggerService & { lines: string[] };

function makeLogger(): SpyLogger {
  const lines: string[] = [];
  const push = (message: string, context?: Record<string, unknown>) => {
    lines.push(`${message} ${JSON.stringify(context ?? {})}`);
  };
  return {
    lines,
    debug: push,
    info: push,
    warn: push,
    error: push,
  } as unknown as SpyLogger;
}

function makeInner(): ReadingProvider & { generate: jest.Mock } {
  const generated: GeneratedReading = { title: 'عنوان', reading: 'متن '.repeat(20) };
  return { generate: jest.fn().mockResolvedValue(generated) };
}

const VALID_REPLY = JSON.stringify({
  interpretationForIntention: 'نیت تو به همین کارت می‌ماند.\n\nراه باز است، آهسته.',
  hope: 'گشایشی در همین کارت هست.',
  caution: 'شتاب، تصویر را تیره می‌کند.',
  practicalAdvice: 'امروز یک قدم کوچک بردار.',
});

function completion(content: string): Response {
  return new Response(JSON.stringify({ choices: [{ message: { content } }] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('parseCardsReading', () => {
  it('accepts a reply with every section', () => {
    const parsed = parseCardsReading(VALID_REPLY);
    expect(parsed.hope).toContain('گشایشی');
  });

  it('refuses a reply missing a section', () => {
    const reply = JSON.parse(VALID_REPLY) as Record<string, unknown>;
    delete reply.hope;
    expect(() => parseCardsReading(JSON.stringify(reply))).toThrow('hope');
  });

  it('refuses a completion that is not JSON', () => {
    expect(() => parseCardsReading('نه یک شیء JSON')).toThrow();
  });
});

describe('CardsReadingProvider', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('passes every other fortune straight through', async () => {
    const inner = makeInner();
    const provider = new CardsReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    await provider.generate(abjad, { intention: 'نیت' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('passes cards through while the flag is off', async () => {
    const inner = makeInner();
    const provider = new CardsReadingProvider(
      inner,
      makeFlags(false),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    await provider.generate(cards, { intention: 'سلامتی' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('falls back to the ordinary provider when no model is configured', async () => {
    const inner = makeInner();
    const provider = new CardsReadingProvider(
      inner,
      makeFlags(true),
      makeConfig({ isConfigured: false }),
      monetization,
      makeLogger(),
    );

    await provider.generate(cards, { intention: 'سلامتی' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('serves the drawn card: real card in the prompt, same card in the reading', async () => {
    const fetchMock = jest.fn().mockResolvedValue(completion(VALID_REPLY));
    global.fetch = fetchMock as never;
    const inner = makeInner();
    const provider = new CardsReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    const out = await provider.generate(cards, { intention: 'سلامتی' });

    expect(inner.generate).not.toHaveBeenCalled();
    expect(out.title).toMatch(/^کارت — /);
    expect(out.reading).toContain('کارتِ تو:');
    expect(out.reading).toContain('معنای سنتی:');
    expect(out.reading).toContain('برای امروز:');

    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(init.body as string);
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[1].content).toContain('کارتِ کشیده‌شده');
    const cardName = out.title.replace('کارت — ', '');
    expect(body.messages[1].content).toContain(cardName);
  });

  it('draws the same card for the same intention on the same day', async () => {
    global.fetch = jest
      .fn()
      .mockImplementation(() => Promise.resolve(completion(VALID_REPLY))) as never;
    const provider = new CardsReadingProvider(
      makeInner(),
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    const a = await provider.generate(cards, { intention: 'سلامتی' });
    const b = await provider.generate(cards, { intention: 'سلامتی' });

    expect(a.title).toBe(b.title);
  });

  it('fails honestly on an upstream error instead of answering canned', async () => {
    global.fetch = jest.fn().mockResolvedValue(new Response('down', { status: 503 })) as never;
    const inner = makeInner();
    const logger = makeLogger();
    const provider = new CardsReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      logger,
    );

    await expect(provider.generate(cards, { intention: 'نیت' })).rejects.toThrow('503');
    expect(inner.generate).not.toHaveBeenCalled();
    expect(logger.lines.join(' ')).toContain('reading.cards.failed');
  });

  it('never writes the offering into the logs', async () => {
    const secret = 'رازی که نباید لاگ شود';
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET')) as never;
    const logger = makeLogger();
    const provider = new CardsReadingProvider(
      makeInner(),
      makeFlags(true),
      makeConfig(),
      monetization,
      logger,
    );

    await expect(provider.generate(cards, { intention: secret })).rejects.toThrow();
    expect(logger.lines.join(' ')).not.toContain(secret);
  });
});
