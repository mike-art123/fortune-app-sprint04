import { AiReadingProvider, parseGeneratedReading } from './ai-reading.provider';
import { MockReadingProvider } from './mock-reading.provider';
import { findFortune } from '../fortune-catalog';
import type { AiConfig } from '../../../config/ai.config';
import type { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';

const hafez = findFortune('hafez')!;

function makeConfig(overrides: Partial<AiConfig> = {}): AiConfig {
  return {
    baseUrl: 'https://proxy.example.com/v1',
    apiKey: 'test-key',
    model: 'gpt-4o-mini',
    timeoutMs: 50,
    maxRetries: 1,
    isConfigured: true,
    ...overrides,
  } as AiConfig;
}

function makeLogger(): AppLoggerService & { warns: string[]; infos: string[] } {
  const warns: string[] = [];
  const infos: string[] = [];
  return {
    warns,
    infos,
    debug: () => undefined,
    info: (message: string) => infos.push(message),
    warn: (message: string) => warns.push(message),
    error: () => undefined,
  } as unknown as AppLoggerService & { warns: string[]; infos: string[] };
}

function completion(content: string): Response {
  return new Response(JSON.stringify({ choices: [{ message: { content } }] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

const VALID = JSON.stringify({
  title: 'پیامی از دیوان',
  reading:
    'نیتی که با خود آوردی شنیده شد.\n\nراه باز است و عجله‌ای در کار نیست.\n\nبرای امروز: یک قدم کوچک بردار.',
});

describe('parseGeneratedReading', () => {
  it('parses a clean JSON completion', () => {
    const out = parseGeneratedReading(VALID);
    expect(out.title).toBe('پیامی از دیوان');
    expect(out.reading).toContain('برای امروز');
  });

  it('recovers from markdown fences', () => {
    expect(parseGeneratedReading('```json\n' + VALID + '\n```').title).toBe('پیامی از دیوان');
  });

  it('recovers a JSON object embedded in prose', () => {
    expect(parseGeneratedReading('البته! ' + VALID + ' امیدوارم خوب باشد.').title).toBe(
      'پیامی از دیوان',
    );
  });

  it('ignores braces that appear inside strings', () => {
    const tricky = JSON.stringify({
      title: 'عنوان }{ عجیب',
      reading: 'متنی به‌قدر کافی بلند برای عبور از حداقلِ طولِ لازمِ این قرارداد.',
    });
    expect(parseGeneratedReading(tricky).title).toBe('عنوان }{ عجیب');
  });

  it('rejects a completion with no title', () => {
    expect(() => parseGeneratedReading('{"reading":"' + 'متن '.repeat(20) + '"}')).toThrow();
  });

  it('rejects a reading that is too short to be real', () => {
    expect(() => parseGeneratedReading('{"title":"الف","reading":"کوتاه"}')).toThrow();
  });

  it('rejects truncated JSON', () => {
    expect(() => parseGeneratedReading('{"title":"الف","reading":')).toThrow();
  });

  it('rejects a JSON array', () => {
    expect(() => parseGeneratedReading('[{"title":"الف"}]')).toThrow();
  });

  it('clamps an overlong title', () => {
    const long = 'ک'.repeat(200);
    const out = parseGeneratedReading(
      JSON.stringify({ title: long, reading: 'متن '.repeat(30) }),
    );
    expect(out.title.length).toBeLessThanOrEqual(80);
  });
});

describe('AiReadingProvider', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('returns the parsed reading on success', async () => {
    global.fetch = jest.fn().mockResolvedValue(completion(VALID)) as never;
    const provider = new AiReadingProvider(makeConfig(), new MockReadingProvider(), makeLogger());

    const out = await provider.generate(hafez, { intention: 'نیت' });

    expect(out.title).toBe('پیامی از دیوان');
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it('calls the configured endpoint with bearer auth and json_object format', async () => {
    const fetchMock = jest.fn().mockResolvedValue(completion(VALID));
    global.fetch = fetchMock as never;
    const provider = new AiReadingProvider(makeConfig(), new MockReadingProvider(), makeLogger());

    await provider.generate(hafez, { intention: 'نیت' });

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://proxy.example.com/v1/chat/completions');
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer test-key');

    const body = JSON.parse(init.body as string);
    expect(body.model).toBe('gpt-4o-mini');
    expect(body.response_format).toEqual({ type: 'json_object' });
    expect(body.messages[0].role).toBe('system');
  });

  it('strips a trailing slash from the configured base URL', async () => {
    const fetchMock = jest.fn().mockResolvedValue(completion(VALID));
    global.fetch = fetchMock as never;
    const provider = new AiReadingProvider(
      makeConfig({ baseUrl: 'https://proxy.example.com/v1/' }),
      new MockReadingProvider(),
      makeLogger(),
    );

    await provider.generate(hafez, {});

    expect(fetchMock.mock.calls[0][0]).toBe('https://proxy.example.com/v1/chat/completions');
  });

  it('retries once on 429 and then succeeds', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce(new Response('slow down', { status: 429 }))
      .mockResolvedValueOnce(completion(VALID));
    global.fetch = fetchMock as never;
    const provider = new AiReadingProvider(makeConfig(), new MockReadingProvider(), makeLogger());

    const out = await provider.generate(hafez, {});

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(out.title).toBe('پیامی از دیوان');
  });

  it('does not retry a 401 and falls back immediately', async () => {
    const fetchMock = jest.fn().mockResolvedValue(new Response('bad key', { status: 401 }));
    global.fetch = fetchMock as never;
    const provider = new AiReadingProvider(makeConfig(), new MockReadingProvider(), makeLogger());

    const out = await provider.generate(hafez, { intention: 'نیت' });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(out.reading.length).toBeGreaterThan(20);
  });

  it('respects maxRetries as an upper bound', async () => {
    const fetchMock = jest.fn().mockResolvedValue(new Response('boom', { status: 503 }));
    global.fetch = fetchMock as never;
    const provider = new AiReadingProvider(
      makeConfig({ maxRetries: 2 }),
      new MockReadingProvider(),
      makeLogger(),
    );

    await provider.generate(hafez, {});

    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it('aborts a slow request and falls back to the mock reading', async () => {
    global.fetch = jest.fn((_url: unknown, init: { signal?: AbortSignal } = {}) => {
      return new Promise<Response>((_resolve, reject) => {
        init.signal?.addEventListener('abort', () =>
          reject(Object.assign(new Error('aborted'), { name: 'AbortError' })),
        );
      });
    }) as never;

    const logger = makeLogger();
    const provider = new AiReadingProvider(
      makeConfig({ timeoutMs: 20, maxRetries: 0 }),
      new MockReadingProvider(),
      logger,
    );

    const out = await provider.generate(hafez, { intention: 'نیت' });

    expect(out.reading.length).toBeGreaterThan(20);
    expect(logger.warns).toContain('reading.ai.fell_back_to_mock');
  });

  it('falls back when the model returns malformed content', async () => {
    global.fetch = jest.fn().mockResolvedValue(completion('این JSON نیست')) as never;
    const provider = new AiReadingProvider(
      makeConfig({ maxRetries: 0 }),
      new MockReadingProvider(),
      makeLogger(),
    );

    const out = await provider.generate(hafez, {});
    const mockOut = await new MockReadingProvider().generate(hafez, {});

    expect(out.reading).toBe(mockOut.reading);
  });

  it('falls back on a network failure', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET')) as never;
    const provider = new AiReadingProvider(
      makeConfig({ maxRetries: 0 }),
      new MockReadingProvider(),
      makeLogger(),
    );

    const out = await provider.generate(hafez, {});

    expect(out.title.length).toBeGreaterThan(0);
  });

  it('never writes the offering into the logs', async () => {
    const secret = 'رازی که نباید لاگ شود';
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET')) as never;
    const logger = makeLogger();
    const provider = new AiReadingProvider(
      makeConfig({ maxRetries: 0 }),
      new MockReadingProvider(),
      logger,
    );

    await provider.generate(hafez, { intention: secret });

    expect([...logger.warns, ...logger.infos].join(' ')).not.toContain(secret);
  });
});
