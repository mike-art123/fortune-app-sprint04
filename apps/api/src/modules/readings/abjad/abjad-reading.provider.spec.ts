import { AbjadReadingProvider, parseAbjadReading } from './abjad-reading.provider';
import { findFortune } from '../fortune-catalog';
import type { AiConfig } from '../../../config/ai.config';
import type { FeatureFlagsService } from '../../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { GeneratedReading, ReadingProvider } from '../providers/reading-provider.interface';

const abjad = findFortune('abjad')!;
const tarot = findFortune('tarot')!;

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
  numberMeaning: 'این عدد از پایداری و بازگشت به ریشه می‌گوید.',
  interpretationForIntention: 'نیت تو در همین جنس آرامش می‌نشیند.\n\nراه باز است، آهسته.',
  hope: 'گشایشی در همین عدد هست.',
  caution: 'شتاب، شمار را به‌هم می‌ریزد.',
  practicalAdvice: 'امروز یک قدم کوچک بردار.',
});

function completion(content: string): Response {
  return new Response(JSON.stringify({ choices: [{ message: { content } }] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('parseAbjadReading', () => {
  it('accepts a reply with every section', () => {
    const parsed = parseAbjadReading(VALID_REPLY);
    expect(parsed.hope).toContain('گشایشی');
    expect(parsed.numberMeaning).toContain('پایداری');
  });

  it('refuses a reply missing a section', () => {
    const reply = JSON.parse(VALID_REPLY) as Record<string, unknown>;
    delete reply.hope;
    expect(() => parseAbjadReading(JSON.stringify(reply))).toThrow('hope');
  });

  it('refuses a completion that is not JSON', () => {
    expect(() => parseAbjadReading('نه یک شیء JSON')).toThrow();
  });
});

describe('AbjadReadingProvider', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('passes every other fortune straight through', async () => {
    const inner = makeInner();
    const provider = new AbjadReadingProvider(inner, makeFlags(true), makeConfig(), makeLogger());

    await provider.generate(tarot, { intention: 'نیت' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('passes abjad through while the flag is off', async () => {
    const inner = makeInner();
    const provider = new AbjadReadingProvider(inner, makeFlags(false), makeConfig(), makeLogger());

    await provider.generate(abjad, { intention: 'حافظ' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('falls back to the ordinary provider when no model is configured', async () => {
    const inner = makeInner();
    const provider = new AbjadReadingProvider(
      inner,
      makeFlags(true),
      makeConfig({ isConfigured: false }),
      makeLogger(),
    );

    await provider.generate(abjad, { intention: 'حافظ' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
  });

  it('steps aside when there is no letter to count', async () => {
    const fetchMock = jest.fn();
    global.fetch = fetchMock as never;
    const inner = makeInner();
    const provider = new AbjadReadingProvider(inner, makeFlags(true), makeConfig(), makeLogger());

    await provider.generate(abjad, { intention: '۱۲۳ !!!' });

    expect(inner.generate).toHaveBeenCalledTimes(1);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('serves the counted number: number in the prompt, number in the reading', async () => {
    const fetchMock = jest.fn().mockResolvedValue(completion(VALID_REPLY));
    global.fetch = fetchMock as never;
    const inner = makeInner();
    const provider = new AbjadReadingProvider(inner, makeFlags(true), makeConfig(), makeLogger());

    const out = await provider.generate(abjad, { intention: 'حافظ' });

    expect(inner.generate).not.toHaveBeenCalled();
    expect(out.title).toContain('عددِ ۹۸۹');
    expect(out.reading).toContain('ح(۸) + ا(۱) + ف(۸۰) + ظ(۹۰۰) = ۹۸۹');
    expect(out.reading).toContain('برای امروز:');

    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    const body = JSON.parse(init.body as string);
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[1].content).toContain('عددِ ۹۸۹');
  });

  it('fails honestly on an upstream error instead of answering canned', async () => {
    global.fetch = jest.fn().mockResolvedValue(new Response('down', { status: 503 })) as never;
    const inner = makeInner();
    const logger = makeLogger();
    const provider = new AbjadReadingProvider(inner, makeFlags(true), makeConfig(), logger);

    await expect(provider.generate(abjad, { intention: 'حافظ' })).rejects.toThrow('503');
    expect(inner.generate).not.toHaveBeenCalled();
    expect(logger.lines.join(' ')).toContain('reading.abjad.failed');
  });

  it('never writes the offering into the logs', async () => {
    const secret = 'رازی که نباید لاگ شود';
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET')) as never;
    const logger = makeLogger();
    const provider = new AbjadReadingProvider(makeInner(), makeFlags(true), makeConfig(), logger);

    await expect(provider.generate(abjad, { intention: secret })).rejects.toThrow();
    expect(logger.lines.join(' ')).not.toContain(secret);
  });
});
