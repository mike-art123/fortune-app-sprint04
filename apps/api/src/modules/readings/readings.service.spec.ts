import { DomainException } from '../../common/exceptions/domain.exception';
import { ReadingsService } from './readings.service';

const provider = {
  generate: jest.fn(),
};

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

const principal = { userId: 'u1', telegramId: '42', roles: ['user'] as const };

function row(id: string, createdAt: string, userId: string | null = 'u1') {
  return {
    id,
    userId,
    fortuneId: 'hafez',
    title: `عنوان ${id}`,
    content: 'متنِ خوانش',
    inputJson: '{}',
    requestId: null,
    createdAt: new Date(createdAt),
  };
}

const repository = {
  create: jest.fn(),
  list: jest.fn(),
  findById: jest.fn(),
};

const entitlements = {
  hasActiveVip: jest.fn(),
};

const freeDaily = {
  freeUsesRemainingToday: jest.fn(),
  consumeFreeToday: jest.fn(),
};

const mediation = {
  consumeEntitlement: jest.fn(),
  restoreEntitlement: jest.fn(),
};

const monetization = {
  enforceAccessLimits: false,
};

const idempotency = {
  check: jest.fn(),
  record: jest.fn(),
};

const service = new ReadingsService(
  repository as never,
  provider as never,
  entitlements as never,
  freeDaily as never,
  mediation as never,
  monetization as never,
  idempotency as never,
  logger as never,
);

function resetHappyPath(): void {
  jest.clearAllMocks();
  monetization.enforceAccessLimits = false;
  provider.generate.mockResolvedValue({ title: 'عنوان', reading: 'متنِ خوانش' });
  repository.create.mockImplementation((r) =>
    Promise.resolve({ id: 'clx1', createdAt: new Date('2026-01-01T00:00:00Z'), ...r }),
  );
  repository.list.mockResolvedValue([]);
  repository.findById.mockResolvedValue(null);
  entitlements.hasActiveVip.mockResolvedValue(false);
  freeDaily.freeUsesRemainingToday.mockResolvedValue(0);
  freeDaily.consumeFreeToday.mockResolvedValue(undefined);
  mediation.consumeEntitlement.mockResolvedValue(undefined);
  mediation.restoreEntitlement.mockResolvedValue(undefined);
  idempotency.check.mockResolvedValue(null);
  idempotency.record.mockResolvedValue(undefined);
}

describe('ReadingsService.create — access orchestration (coins removed)', () => {
  beforeEach(resetHappyPath);

  it('persists the reading under the user with no coin machinery', async () => {
    const res = await service.create({ fortuneId: 'hafez', input: {} }, 'req-1', principal, null);

    expect(repository.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', fortuneId: 'hafez', requestId: 'req-1' }),
    );
    expect(res.fortune).toBe('hafez');
    expect(mediation.consumeEntitlement).not.toHaveBeenCalled();
  });

  it('VIP readings never touch the free allowance or entitlements', async () => {
    entitlements.hasActiveVip.mockResolvedValue(true);

    await service.create({ fortuneId: 'hafez', input: {} }, null, principal, null);

    expect(freeDaily.freeUsesRemainingToday).not.toHaveBeenCalled();
    expect(freeDaily.consumeFreeToday).not.toHaveBeenCalled();
    expect(mediation.consumeEntitlement).not.toHaveBeenCalled();
  });

  it('counts the free daily allowance only after a successful reading', async () => {
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);

    await service.create({ fortuneId: 'hafez', input: {} }, null, principal, null);

    expect(freeDaily.consumeFreeToday).toHaveBeenCalledWith('u1', 'hafez');
  });

  it('does not count the allowance when generation fails (retry stays free)', async () => {
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);
    provider.generate.mockRejectedValue(new Error('provider exploded'));

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'READING_FAILED' });
    expect(freeDaily.consumeFreeToday).not.toHaveBeenCalled();
  });

  it('a counting hiccup never takes the reading away from the user', async () => {
    freeDaily.freeUsesRemainingToday.mockResolvedValue(1);
    freeDaily.consumeFreeToday.mockRejectedValue(new Error('db blip'));

    const res = await service.create({ fortuneId: 'hafez', input: {} }, null, principal, null);

    expect(res.fortune).toBe('hafez');
    expect(logger.error).toHaveBeenCalledWith(
      'reading.freeDaily.count.failed',
      expect.objectContaining({ fortuneId: 'hafez' }),
    );
  });

  it('consumes the ad entitlement before generating when provided', async () => {
    const dto = { fortuneId: 'tarot', adEntitlementId: 'ent1', input: {} };

    await service.create(dto, null, principal, null);

    expect(mediation.consumeEntitlement).toHaveBeenCalledWith('u1', 'ent1', 'tarot');
    const consumeOrder = mediation.consumeEntitlement.mock.invocationCallOrder[0] as number;
    const generateOrder = provider.generate.mock.invocationCallOrder[0] as number;
    expect(consumeOrder).toBeLessThan(generateOrder);
  });

  const adDto = { fortuneId: 'tarot', adEntitlementId: 'ent1', input: {} };

  it('restores the ad entitlement when generation fails (retry entitlement)', async () => {
    provider.generate.mockRejectedValue(new Error('provider exploded'));

    await expect(service.create(adDto, null, principal, null)).rejects.toMatchObject({
      code: 'READING_FAILED',
    });
    expect(mediation.restoreEntitlement).toHaveBeenCalledWith('ent1');
  });

  it('restores the ad entitlement when persistence fails', async () => {
    repository.create.mockRejectedValue(new Error('db down'));

    await expect(service.create(adDto, null, principal, null)).rejects.toMatchObject({
      code: 'READING_FAILED',
    });
    expect(mediation.restoreEntitlement).toHaveBeenCalledWith('ent1');
  });

  it('surfaces the original error even when the restore itself fails', async () => {
    provider.generate.mockRejectedValue(new Error('provider exploded'));
    mediation.restoreEntitlement.mockRejectedValue(new Error('restore infra down'));

    await expect(service.create(adDto, null, principal, null)).rejects.toMatchObject({
      code: 'READING_FAILED',
    });
    expect(logger.error).toHaveBeenCalledWith(
      'reading.adEntitlement.restore.failed',
      expect.objectContaining({ entitlementId: 'ent1' }),
    );
  });

  it('refuses with ACCESS_REQUIRED when enforcement is on and no path exists', async () => {
    monetization.enforceAccessLimits = true;

    await expect(
      service.create({ fortuneId: 'tarot', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'ACCESS_REQUIRED' });
    expect(provider.generate).not.toHaveBeenCalled();
  });

  it('lets the reading through free while enforcement is off', async () => {
    const res = await service.create({ fortuneId: 'tarot', input: {} }, null, principal, null);

    expect(res.fortune).toBe('tarot');
    expect(freeDaily.consumeFreeToday).not.toHaveBeenCalled();
  });

  it('replays an identical idempotent request without consuming anything', async () => {
    const stored = {
      id: 'clx-old',
      fortune: 'hafez',
      title: 'عنوان',
      reading: 'متن',
      createdAt: '2026-01-01T00:00:00.000Z',
    };
    idempotency.check.mockResolvedValue(JSON.stringify(stored));

    const res = await service.create(
      { fortuneId: 'hafez', input: {} },
      null,
      principal,
      'key-12345678',
    );

    expect(res).toEqual(stored);
    expect(provider.generate).not.toHaveBeenCalled();
    expect(mediation.consumeEntitlement).not.toHaveBeenCalled();
  });

  it('records the idempotency result under the provided key', async () => {
    await service.create({ fortuneId: 'hafez', input: {} }, null, principal, 'key-12345678');

    expect(idempotency.record).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', operation: 'reading.create', key: 'key-12345678' }),
    );
  });

  it('rejects an unknown fortune before touching access services', async () => {
    await expect(
      service.create({ fortuneId: 'nope', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    expect(entitlements.hasActiveVip).not.toHaveBeenCalled();
  });

  it('validates the offering (dream needs words; love needs both names)', async () => {
    await expect(
      service.create({ fortuneId: 'dream', input: { narration: 'خواب' } }, null, principal, null),
    ).rejects.toBeInstanceOf(DomainException);
    await expect(
      service.create({ fortuneId: 'love', input: { selfName: 'سارا' } }, null, principal, null),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    expect(provider.generate).not.toHaveBeenCalled();
  });
});

describe('ReadingsService.list — scoped history', () => {
  beforeEach(resetHappyPath);

  it('scopes the query to the authenticated user, newest-first defaults', async () => {
    repository.list.mockResolvedValue([row('c3', '2026-01-03'), row('c2', '2026-01-02')]);

    const page = await service.list({}, principal);

    expect(repository.list).toHaveBeenCalledWith({ userId: 'u1', limit: 20, cursorId: undefined });
    expect(page.items.map((i) => i.id)).toEqual(['c3', 'c2']);
    expect(page.nextCursor).toBeNull();
  });

  it('returns an opaque nextCursor only when an extra row came back', async () => {
    repository.list.mockResolvedValue([
      row('c3', '2026-01-03'),
      row('c2', '2026-01-02'),
      row('c1', '2026-01-01'),
    ]);

    const page = await service.list({ limit: 2 }, principal);

    expect(page.items).toHaveLength(2);
    expect(page.nextCursor).not.toBeNull();
    expect(page.nextCursor).not.toContain('c2'); // opaque, not the raw id
  });

  it('treats a corrupt cursor as page one, not as an error', async () => {
    repository.list.mockResolvedValue([row('c1', '2026-01-01')]);

    const page = await service.list({ cursor: '!!!not-base64url!!!' }, principal);

    expect(repository.list).toHaveBeenCalledWith({ userId: 'u1', limit: 20, cursorId: undefined });
    expect(page.items).toHaveLength(1);
  });
});

describe('ReadingsService.getById — ownership', () => {
  beforeEach(resetHappyPath);

  it('returns the shaped reading when it belongs to the caller', async () => {
    repository.findById.mockResolvedValue(row('c9', '2026-01-09'));

    const res = await service.getById('c9', principal);

    expect(res.id).toBe('c9');
  });

  it("hides another user's reading behind NOT_FOUND", async () => {
    repository.findById.mockResolvedValue(row('c9', '2026-01-09', 'someone-else'));

    await expect(service.getById('c9', principal)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('hides legacy ownerless rows as well', async () => {
    repository.findById.mockResolvedValue(row('c9', '2026-01-09', null));

    await expect(service.getById('c9', principal)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('raises NOT_FOUND when nothing exists', async () => {
    repository.findById.mockResolvedValue(null);

    await expect(service.getById('missing', principal)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });
});
