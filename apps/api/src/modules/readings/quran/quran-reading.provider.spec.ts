import { QuranReadingProvider, parseQuranReading } from './quran-reading.provider';
import { findFortune } from '../fortune-catalog';
import type { AiConfig } from '../../../config/ai.config';
import type { MonetizationConfig } from '../../../config/monetization.config';
import type { FeatureFlagsService } from '../../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { GeneratedReading, ReadingProvider } from '../providers/reading-provider.interface';

const quran = findFortune('quran')!;
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
  reflectionForIntention: 'این آیه برای نیتِ تو نویدِ گشایش دارد.\n\nآهسته و امیدوار پیش برو.',
  hope: 'روشنایی در همین آیه هست.',
  practicalAdvice: 'امروز لحظه‌ای برای آرامش و دعا بگذار.',
});

function completion(content: string): Response {
  return new Response(JSON.stringify({ choices: [{ message: { content } }] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('parseQuranReading', () => {
  it('accepts a reply with every section', () => {
    const parsed = parseQuranReading(VALID_REPLY);
    expect(parsed.hope).toContain('روشنایی');
  });

  it('refuses a reply missing a section', () => {
    const reply = JSON.parse(VALID_REPLY) as Record<string, unknown>;
    delete reply.hope;
    expect(() => parseQuranReading(JSON.stringify(reply))).toThrow('hope');
  });

  it('refuses a completion that is not JSON', () => {
    expect(() => parseQuranReading('نه یک شیء JSON')).toThrow();
  });
});

describe('QuranReadingProvider', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('passes every other fortune straight through', async () => {
    const inner = makeInner();
    const provider = new QuranReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    await provider.generate(abjad, { intention: 'نیت' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('passes quran through while the flag is off', async () => {
    const inner = makeInner();
    const provider = new QuranReadingProvider(
      inner,
      makeFlags(false),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    await provider.generate(quran, { intention: 'سلامتی' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('falls back to the ordinary provider when no model is configured', async () => {
    const inner = makeInner();
    const provider = new QuranReadingProvider(
      inner,
      makeFlags(true),
      makeConfig({ isConfigured: false }),
      monetization,
      makeLogger(),
    );

    await provider.generate(quran, { intention: 'سلامتی' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('serves the drawn verse and keeps the humility note', async () => {
    const fetchMock = jest.fn().mockResolvedValue(completion(VALID_REPLY));
    global.fetch = fetchMock as never;
    const inner = makeInner();
    const provider = new QuranReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    const out = await provider.generate(quran, { intention: 'سلامتی' });

    expect(inner.generate).not.toHaveBeenCalled();
    expect(out.title).toMatch(/^تفأل به قرآن — سورهٔ /);
    expect(out.reading).toContain('ترجمه (');
    expect(out.reading).toContain('برای امروز:');
    expect(out.reading).toContain('استخارهٔ حقیقی با نماز');

    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(init.body as string);
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[1].content).toContain('آیه (سورهٔ');
  });

  it('turns to the same verse for the same intention on the same day', async () => {
    global.fetch = jest
      .fn()
      .mockImplementation(() => Promise.resolve(completion(VALID_REPLY))) as never;
    const provider = new QuranReadingProvider(
      makeInner(),
      makeFlags(true),
      makeConfig(),
      monetization,
      makeLogger(),
    );

    const a = await provider.generate(quran, { intention: 'سلامتی' });
    const b = await provider.generate(quran, { intention: 'سلامتی' });

    expect(a.title).toBe(b.title);
  });

  it('fails honestly on an upstream error instead of answering canned', async () => {
    global.fetch = jest.fn().mockResolvedValue(new Response('down', { status: 503 })) as never;
    const inner = makeInner();
    const logger = makeLogger();
    const provider = new QuranReadingProvider(
      inner,
      makeFlags(true),
      makeConfig(),
      monetization,
      logger,
    );

    await expect(provider.generate(quran, { intention: 'نیت' })).rejects.toThrow('503');
    expect(inner.generate).not.toHaveBeenCalled();
    expect(logger.lines.join(' ')).toContain('reading.quran.failed');
  });

  it('never writes the offering into the logs', async () => {
    const secret = 'رازی که نباید لاگ شود';
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET')) as never;
    const logger = makeLogger();
    const provider = new QuranReadingProvider(
      makeInner(),
      makeFlags(true),
      makeConfig(),
      monetization,
      logger,
    );

    await expect(provider.generate(quran, { intention: secret })).rejects.toThrow();
    expect(logger.lines.join(' ')).not.toContain(secret);
  });
});
