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
  assessReading: jest.fn(),
};

const wallet = {
  debitForReading: jest.fn(),
  refundDebit: jest.fn(),
};

const idempotency = {
  check: jest.fn(),
  record: jest.fn(),
};

const service = new ReadingsService(
  repository as never,
  provider as never,
  entitlements as never,
  wallet as never,
  idempotency as never,
  logger as never,
);

function resetHappyPath(): void {
  jest.clearAllMocks();
  provider.generate.mockResolvedValue({ title: 'عنوان', reading: 'متنِ خوانش' });
  repository.create.mockImplementation((r) =>
    Promise.resolve({ id: 'clx1', createdAt: new Date('2026-01-01T00:00:00Z'), ...r }),
  );
  repository.list.mockResolvedValue([]);
  repository.findById.mockResolvedValue(null);
  entitlements.assessReading.mockResolvedValue({ covered: false, source: null, cost: 5 });
  wallet.debitForReading.mockResolvedValue({ transactionId: 'd1', amount: -5 });
  wallet.refundDebit.mockResolvedValue({ transactionId: 'r1', amount: 5 });
  idempotency.check.mockResolvedValue(null);
  idempotency.record.mockResolvedValue(undefined);
}

describe('ReadingsService.create — entitlement and debit orchestration', () => {
  beforeEach(resetHappyPath);

  it('debits before generating and persists the reading under the user', async () => {
    const res = await service.create({ fortuneId: 'hafez', input: {} }, 'req-1', principal, null);

    expect(entitlements.assessReading).toHaveBeenCalledWith('u1');
    expect(wallet.debitForReading).toHaveBeenCalledWith({
      userId: 'u1',
      cost: 5,
      reason: 'reading:hafez',
      idempotencyRefId: null,
    });
    expect(repository.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', fortuneId: 'hafez', requestId: 'req-1' }),
    );
    expect(res.fortune).toBe('hafez');
    expect(wallet.refundDebit).not.toHaveBeenCalled();
  });

  it('skips the debit entirely under an active subscription', async () => {
    entitlements.assessReading.mockResolvedValue({
      covered: true,
      source: 'subscription',
      cost: 0,
    });

    await service.create({ fortuneId: 'hafez', input: {} }, null, principal, null);

    expect(wallet.debitForReading).not.toHaveBeenCalled();
  });

  it('propagates INSUFFICIENT_COINS without generating anything', async () => {
    wallet.debitForReading.mockRejectedValue(
      new DomainException('INSUFFICIENT_COINS', 'سکه کافی نیست.'),
    );

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'INSUFFICIENT_COINS' });
    expect(provider.generate).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('refunds the debit when generation fails, then surfaces READING_FAILED', async () => {
    provider.generate.mockRejectedValue(new Error('provider exploded'));

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'READING_FAILED' });
    expect(wallet.refundDebit).toHaveBeenCalledWith('d1', 'reading:failed');
  });

  it('refunds the debit when persistence fails', async () => {
    repository.create.mockRejectedValue(new Error('db down'));

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'READING_FAILED' });
    expect(wallet.refundDebit).toHaveBeenCalledWith('d1', 'reading:failed');
  });

  it('does not refund when there was nothing debited (covered reading fails)', async () => {
    entitlements.assessReading.mockResolvedValue({
      covered: true,
      source: 'subscription',
      cost: 0,
    });
    provider.generate.mockRejectedValue(new Error('boom'));

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'READING_FAILED' });
    expect(wallet.refundDebit).not.toHaveBeenCalled();
  });

  it('surfaces the original error even when the refund itself fails (and logs it)', async () => {
    provider.generate.mockRejectedValue(new Error('provider exploded'));
    wallet.refundDebit.mockRejectedValue(new Error('refund infra down'));

    await expect(
      service.create({ fortuneId: 'hafez', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'READING_FAILED' });
    expect(logger.error).toHaveBeenCalledWith(
      'reading.refund.failed',
      expect.objectContaining({ debitTransactionId: 'd1' }),
    );
  });

  it('replays an identical idempotent request without a second debit', async () => {
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
    expect(wallet.debitForReading).not.toHaveBeenCalled();
    expect(provider.generate).not.toHaveBeenCalled();
  });

  it('passes the idempotency key into the debit as the DB-level backstop', async () => {
    await service.create({ fortuneId: 'hafez', input: {} }, null, principal, 'key-12345678');

    expect(wallet.debitForReading).toHaveBeenCalledWith(
      expect.objectContaining({ idempotencyRefId: 'key-12345678' }),
    );
    expect(idempotency.record).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'u1', operation: 'reading.create', key: 'key-12345678' }),
    );
  });

  it('rejects an unknown fortune before touching entitlements or the wallet', async () => {
    await expect(
      service.create({ fortuneId: 'nope', input: {} }, null, principal, null),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    expect(entitlements.assessReading).not.toHaveBeenCalled();
  });

  it('validates the offering (dream needs words; love needs both names)', async () => {
    await expect(
      service.create({ fortuneId: 'dream', input: { narration: 'خواب' } }, null, principal, null),
    ).rejects.toBeInstanceOf(DomainException);
    await expect(
      service.create({ fortuneId: 'love', input: { selfName: 'سارا' } }, null, principal, null),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    expect(wallet.debitForReading).not.toHaveBeenCalled();
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
