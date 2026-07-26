import type { AiConfig } from '../../config/ai.config';
import type { MonetizationConfig } from '../../config/monetization.config';
import type { PrismaService } from '../../infrastructure/database/prisma.service';
import type { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import type { ReadingsRepository } from '../readings/readings.repository';
import type { UsersService } from '../users/users.service';
import { HistorySummaryService } from './history-summary.service';

const logger = {
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
} as unknown as AppLoggerService;

const monetization = { appTimezone: 'Asia/Tehran' } as unknown as MonetizationConfig;

function config(configured = true): AiConfig {
  return {
    baseUrl: 'https://llm.test/v1',
    apiKey: 'k',
    model: 'test-model',
    timeoutMs: 50,
    maxRetries: 0,
    isConfigured: configured,
  } as unknown as AiConfig;
}

function flags(enabled: boolean): FeatureFlagsService {
  return { isEnabled: jest.fn().mockResolvedValue(enabled) } as unknown as FeatureFlagsService;
}

function users(optOut = false): UsersService {
  return {
    getProfile: jest.fn().mockResolvedValue({
      displayName: 'علی',
      birthMonth: 'MEHR',
      locale: 'fa',
      onboardingCompleted: true,
      personalizationOptOut: optOut,
    }),
  } as unknown as UsersService;
}

/** Two readings, both this month, so there is always something to describe. */
function readings(): ReadingsRepository {
  const now = Date.now();
  const day = 24 * 60 * 60 * 1000;
  return {
    listSince: jest.fn().mockResolvedValue([
      { id: 'r1', fortuneId: 'hafez', createdAt: new Date(now - day) },
      { id: 'r2', fortuneId: 'hafez', createdAt: new Date(now - 2 * day) },
    ]),
  } as unknown as ReadingsRepository;
}

function prisma(row: { fingerprint: string; summary: string } | null = null): PrismaService {
  return {
    aiSummaryCache: {
      findUnique: jest.fn().mockResolvedValue(row),
      upsert: jest.fn().mockResolvedValue({}),
    },
  } as unknown as PrismaService;
}

function answering(content: string): jest.Mock {
  return jest.fn().mockResolvedValue({
    ok: true,
    json: async () => ({ choices: [{ message: { content } }] }),
  });
}

const GOOD = '{"summary":"این ماه دو بار سراغ فال حافظ رفتی."}';

/**
 * The summary is a courtesy laid over arithmetic the server already did. Every
 * path below still answers — the only thing an unhappy path costs is the warmer
 * phrasing.
 */
describe('HistorySummaryService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  function build(
    overrides: {
      enabled?: boolean;
      configured?: boolean;
      optOut?: boolean;
      cache?: { fingerprint: string; summary: string } | null;
      db?: PrismaService;
    } = {},
  ): { service: HistorySummaryService; db: PrismaService } {
    const db = overrides.db ?? prisma(overrides.cache ?? null);
    const service = new HistorySummaryService(
      readings(),
      users(overrides.optOut ?? false),
      db,
      config(overrides.configured ?? true),
      monetization,
      flags(overrides.enabled ?? true),
      logger,
    );
    return { service, db };
  }

  it('never calls the model while the flag is off', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build({ enabled: false });
    const view = await service.summarize('u1', 'last30');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(view.source).toBe('rules');
    expect(view.summary).toContain('فال گرفتی');
  });

  it('never calls the model when no model is configured', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build({ configured: false });
    await expect(service.summarize('u1', 'last30')).resolves.toMatchObject({ source: 'rules' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('sends nothing anywhere when the reader turned personalization off', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build({ optOut: true });
    const view = await service.summarize('u1', 'last30');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(view.source).toBe('rules');
    // The counts are still theirs to see — only the wire is closed.
    expect(view.total).toBe(2);
  });

  it('shows the phrased sentence and remembers it for the same readings', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service, db } = build();
    const view = await service.summarize('u1', 'last30');

    expect(view.source).toBe('ai');
    expect(view.summary).toBe('این ماه دو بار سراغ فال حافظ رفتی.');
    expect(db.aiSummaryCache.upsert).toHaveBeenCalledTimes(1);
  });

  it('never sends a reading, a name or an id to the model', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build();
    await service.summarize('u1', 'last30');

    const body = String((fetchMock.mock.calls[0]?.[1] as { body: string }).body);
    expect(body).not.toContain('علی');
    expect(body).not.toContain('r1');
    expect(body).not.toContain('u1');
  });

  it('reuses a cached summary while the readings behind it are unchanged', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    // Learn the fingerprint the way the service computes it, then replay it.
    const first = await build().service.summarize('u1', 'last30');
    expect(first.source).toBe('ai');

    const db = prisma({ fingerprint: fingerprintOf(first), summary: 'از پیش نوشته شده.' });
    fetchMock.mockClear();
    const { service } = build({ db });
    const view = await service.summarize('u1', 'last30');

    expect(view.summary).toBe('از پیش نوشته شده.');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('ignores a cached summary that describes different readings', async () => {
    const fetchMock = answering(GOOD);
    global.fetch = fetchMock as unknown as typeof fetch;

    const db = prisma({ fingerprint: 'last30:9:9:gone', summary: 'دربارهٔ فالی که پاک شده.' });
    const { service } = build({ db });
    const view = await service.summarize('u1', 'last30');

    expect(view.summary).not.toContain('پاک شده');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('falls back to the plain sentences when the answer is not a summary', async () => {
    for (const bad of [
      '{"summary":"Sorry, I cannot help."}',
      '{"summary":"<b>سلام</b>"}',
      '{"summary":"ببین https://example.com"}',
      '{"summary":""}',
      'not json at all',
    ]) {
      global.fetch = answering(bad) as unknown as typeof fetch;
      const { service } = build();
      const view = await service.summarize('u1', 'last30');
      expect(view.source).toBe('rules');
      expect(view.summary).toContain('فال گرفتی');
    }
  });

  it('answers calmly when the model is unreachable', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('boom')) as unknown as typeof fetch;

    const { service } = build();
    await expect(service.summarize('u1', 'last30')).resolves.toMatchObject({ source: 'rules' });
  });

  it('hands back the readings every number was counted from', async () => {
    global.fetch = answering(GOOD) as unknown as typeof fetch;

    const { service } = build();
    const view = await service.summarize('u1', 'last30');

    expect(view.sourceIds).toEqual(['r1', 'r2']);
    expect(view.byFortune).toEqual([{ fortuneId: 'hafez', titleFa: 'فال حافظ', count: 2 }]);
    expect(view.rangeLabelFa).toBe('سی روز گذشته');
  });
});

/** The service's own fingerprint rule, re-derived from a returned view. */
function fingerprintOf(view: { range: string; total: number; sourceIds: string[] }): string {
  return `${view.range}:${view.total}:0:${view.sourceIds.join(',')}`;
}
