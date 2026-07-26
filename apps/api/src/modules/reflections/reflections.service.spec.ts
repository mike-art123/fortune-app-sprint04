import type { AiConfig } from '../../config/ai.config';
import type { PrismaService } from '../../infrastructure/database/prisma.service';
import type { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import type { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { promptFor } from './reflection-feelings';
import { ReflectionsService } from './reflections.service';

const logger = {
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
} as unknown as AppLoggerService;

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

const ROW = {
  id: 'e1',
  readingId: 'r1',
  feeling: 'calm',
  note: 'امشب آرام‌تر بودم.',
  createdAt: new Date('2026-07-26T06:00:00.000Z'),
  updatedAt: new Date('2026-07-26T06:00:00.000Z'),
};

function db(existing: { id: string } | null = null): {
  service: PrismaService;
  create: jest.Mock;
  update: jest.Mock;
  deleteMany: jest.Mock;
} {
  const create = jest.fn().mockResolvedValue(ROW);
  const update = jest.fn().mockResolvedValue(ROW);
  const deleteMany = jest.fn().mockResolvedValue({ count: 1 });
  const service = {
    reflectionEntry: {
      findMany: jest.fn().mockResolvedValue([ROW]),
      findFirst: jest.fn().mockResolvedValue(existing),
      create,
      update,
      deleteMany,
    },
  } as unknown as PrismaService;
  return { service, create, update, deleteMany };
}

function answering(content: string): jest.Mock {
  return jest.fn().mockResolvedValue({
    ok: true,
    json: async () => ({ choices: [{ message: { content } }] }),
  });
}

function build(
  overrides: { enabled?: boolean; configured?: boolean; existing?: { id: string } | null } = {},
): {
  service: ReflectionsService;
  store: ReturnType<typeof db>;
} {
  const store = db(overrides.existing ?? null);
  const service = new ReflectionsService(
    store.service,
    config(overrides.configured ?? true),
    flags(overrides.enabled ?? true),
    logger,
  );
  return { service, store };
}

/**
 * The diary. Nothing here may read the note, nothing may send it anywhere, and
 * a heavier feeling must never be handed to a model.
 */
describe('ReflectionsService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  it('writes a new reflection and hands it straight back', async () => {
    const { service, store } = build();
    const view = await service.save('u1', {
      readingId: 'r1',
      feeling: 'calm',
      note: '  امشب آرام‌تر بودم.  ',
    });

    expect(store.create).toHaveBeenCalledTimes(1);
    const data = (store.create.mock.calls[0]?.[0] as { data: { note: string } }).data;
    expect(data.note).toBe('امشب آرام‌تر بودم.');
    expect(view.feelingFa).toBe('آرام');
  });

  it('edits the same reading instead of stacking a second copy', async () => {
    const { service, store } = build({ existing: { id: 'e1' } });
    await service.save('u1', { readingId: 'r1', feeling: 'hopeful', note: 'دوباره' });

    expect(store.update).toHaveBeenCalledTimes(1);
    expect(store.create).not.toHaveBeenCalled();
  });

  it('never logs the note, only the word the app offered', async () => {
    const { service } = build();
    await service.save('u1', { readingId: 'r1', feeling: 'calm', note: 'یک چیز خصوصی' });

    const info = logger.info as unknown as jest.Mock;
    for (const call of info.mock.calls) {
      expect(JSON.stringify(call)).not.toContain('خصوصی');
    }
    expect(info).toHaveBeenCalledWith('reflection.saved', { feeling: 'calm' });
  });

  it('refuses to delete somebody else’s entry', async () => {
    const { service, store } = build();
    store.deleteMany.mockResolvedValueOnce({ count: 0 });
    await expect(service.remove('u1', 'e9')).rejects.toThrow();

    const where = (store.deleteMany.mock.calls[0]?.[0] as { where: { userId: string } }).where;
    expect(where.userId).toBe('u1');
  });

  it('never asks a model about a heavier feeling', async () => {
    const fetchMock = answering('{"question":"چه چیزی آزارت می‌دهد؟"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build();
    for (const feeling of ['worried', 'heavy'] as const) {
      const prompt = await service.prompt(feeling);
      expect(prompt).toEqual(promptFor(feeling));
      expect(prompt.tender).toBe(true);
    }
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('never sends the model anything but the feeling', async () => {
    const fetchMock = answering('{"question":"امروز چه چیزی آرامت کرد؟"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    const { service } = build();
    await service.prompt('calm');

    const body = String((fetchMock.mock.calls[0]?.[1] as { body: string }).body);
    expect(body).toContain('آرام');
    expect(body).not.toContain('امشب');
    expect(body).not.toContain('u1');
    expect(body).not.toContain('r1');
  });

  it('falls back to the written line whenever the answer is unusable', async () => {
    for (const bad of ['{"question":"You seem calm."}', 'nonsense', '{"question":""}']) {
      global.fetch = answering(bad) as unknown as typeof fetch;
      const { service } = build();
      await expect(service.prompt('calm')).resolves.toEqual(promptFor('calm'));
    }
  });

  it('uses the written line while the flag is off, or no model is configured', async () => {
    const fetchMock = answering('{"question":"امروز چطور بود؟"}');
    global.fetch = fetchMock as unknown as typeof fetch;

    await expect(build({ enabled: false }).service.prompt('calm')).resolves.toEqual(
      promptFor('calm'),
    );
    await expect(build({ configured: false }).service.prompt('calm')).resolves.toEqual(
      promptFor('calm'),
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('pages newest first and stops when there is no more', async () => {
    const { service } = build();
    const page = await service.list('u1', 20);

    expect(page.items).toHaveLength(1);
    expect(page.items[0]?.note).toBe('امشب آرام‌تر بودم.');
    expect(page.nextCursor).toBeNull();
  });
});
