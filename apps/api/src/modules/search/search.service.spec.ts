import type { AiConfig } from '../../config/ai.config';
import type { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { AI_BAR_FLAG, SearchService } from './search.service';

const logger = {
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
} as unknown as AppLoggerService;

function config(overrides: Partial<{ configured: boolean }> = {}): AiConfig {
  return {
    baseUrl: 'https://llm.test/v1',
    apiKey: 'k',
    model: 'test-model',
    timeoutMs: 50,
    maxRetries: 0,
    isConfigured: overrides.configured ?? true,
  } as unknown as AiConfig;
}

function flags(enabled: boolean): FeatureFlagsService {
  return { isEnabled: jest.fn().mockResolvedValue(enabled) } as unknown as FeatureFlagsService;
}

function answering(content: string): jest.Mock {
  return jest.fn().mockResolvedValue({
    ok: true,
    json: async () => ({ choices: [{ message: { content } }] }),
  });
}

/**
 * A search box must never fail loudly and must never be the thing that invents
 * a destination. Every unhappy path below ends in the same calm "nothing".
 */
describe('SearchService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  it('never calls the model while the flag is off', async () => {
    const fetchMock = answering('{"kind":"fortune","fortuneId":"hafez"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    const service = new SearchService(config(), flags(false), logger);
    await expect(service.interpret('یه فال بگیر')).resolves.toEqual({ kind: 'none' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('never calls the model when no model is configured', async () => {
    const fetchMock = answering('{"kind":"fortune","fortuneId":"hafez"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    const service = new SearchService(config({ configured: false }), flags(true), logger);
    await expect(service.interpret('یه فال بگیر')).resolves.toEqual({ kind: 'none' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('returns the fortune the model chose, named by the catalog', async () => {
    global.fetch = answering('{"kind":"fortune","fortuneId":"dream"}') as unknown as typeof fetch;

    const service = new SearchService(config(), flags(true), logger);
    await expect(service.interpret('دیشب خواب دریا دیدم')).resolves.toEqual({
      kind: 'fortune',
      fortuneId: 'dream',
      titleFa: 'تعبیر خواب',
    });
  });

  it('recovers an answer wrapped in fences or chatter', async () => {
    global.fetch = answering(
      'حتماً!\n```json\n{"kind":"screen","screen":"history"}\n```',
    ) as unknown as typeof fetch;

    const service = new SearchService(config(), flags(true), logger);
    await expect(service.interpret('فال‌های قبلی من')).resolves.toEqual({
      kind: 'screen',
      screen: 'history',
    });
  });

  it('answers nothing when the model invents an id', async () => {
    global.fetch = answering(
      '{"kind":"fortune","fortuneId":"crystal-ball"}',
    ) as unknown as typeof fetch;

    const service = new SearchService(config(), flags(true), logger);
    await expect(service.interpret('یه چیز عجیب')).resolves.toEqual({ kind: 'none' });
  });

  it('answers nothing when the model returns prose, an error or nothing at all', async () => {
    const service = new SearchService(config(), flags(true), logger);

    global.fetch = answering('نمی‌دانم چه بگویم') as unknown as typeof fetch;
    await expect(service.interpret('سلام')).resolves.toEqual({ kind: 'none' });

    global.fetch = jest
      .fn()
      .mockResolvedValue({ ok: false, status: 500 }) as unknown as typeof fetch;
    await expect(service.interpret('سلام')).resolves.toEqual({ kind: 'none' });

    global.fetch = jest.fn().mockRejectedValue(new Error('network')) as unknown as typeof fetch;
    await expect(service.interpret('سلام')).resolves.toEqual({ kind: 'none' });
  });

  it('does not ask about an empty question', async () => {
    const fetchMock = answering('{"kind":"none"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    const service = new SearchService(config(), flags(true), logger);
    await expect(service.interpret('   ')).resolves.toEqual({ kind: 'none' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('never writes the question into the logs', async () => {
    global.fetch = answering('{"kind":"screen","screen":"profile"}') as unknown as typeof fetch;

    const service = new SearchService(config(), flags(true), logger);
    await service.interpret('اشتراکم تمام شده و اسمم مریم است');

    const written = JSON.stringify((logger.info as unknown as jest.Mock).mock.calls);
    expect(written).not.toContain('مریم');
    expect(written).toContain('queryLength');
  });

  it('reads the flag by its documented key', async () => {
    const flagService = flags(false);
    const service = new SearchService(config(), flagService, logger);
    await service.interpret('چیزی');
    expect(flagService.isEnabled).toHaveBeenCalledWith(AI_BAR_FLAG);
  });
});
