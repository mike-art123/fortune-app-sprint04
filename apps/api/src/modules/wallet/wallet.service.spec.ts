import { WalletService } from './wallet.service';

const config = { starterCoins: 30, readingCostCoins: 5 };

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

/** Marker object standing in for the Prisma transaction client. */
const TX = { __tx: true };

const transactions = {
  run: jest.fn().mockImplementation((work: (tx: unknown) => Promise<unknown>) => work(TX)),
};

function wallet(id: string, balance: number) {
  return {
    id,
    userId: 'u1',
    anonId: null,
    balance,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
  };
}

function txRow(
  id: string,
  amount: number,
  kind: string,
  createdAt = '2026-01-01T00:00:00Z',
  extra: Partial<{ refType: string | null; refId: string | null; walletId: string }> = {},
) {
  return {
    id,
    walletId: extra.walletId ?? 'w1',
    amount,
    kind,
    reason: kind === 'starter' ? 'اعتبار آغازین' : null,
    refType: extra.refType ?? null,
    refId: extra.refId ?? null,
    createdAt: new Date(createdAt),
  };
}

const repository = {
  findByUserId: jest.fn(),
  createWithStarter: jest.fn(),
  listTransactions: jest.fn(),
  decrementIfAffordable: jest.fn(),
  incrementBalance: jest.fn(),
  appendLedgerRow: jest.fn(),
  findTransactionById: jest.fn(),
  findByKindAndRef: jest.fn(),
};

const service = new WalletService(
  repository as never,
  config as never,
  transactions as never,
  logger as never,
);

const uniqueViolation = () => Object.assign(new Error('unique constraint'), { code: 'P2002' });

describe('WalletService.getWalletForUser', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns an existing wallet without creating anything', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 25));
    repository.listTransactions.mockResolvedValue([txRow('t1', 30, 'starter')]);

    const res = await service.getWalletForUser('u1');

    expect(res.balance).toBe(25);
    expect(repository.createWithStarter).not.toHaveBeenCalled();
  });

  it('creates a wallet with the configured starter credit on first sight', async () => {
    repository.findByUserId.mockResolvedValue(null);
    repository.createWithStarter.mockResolvedValue(wallet('w1', 30));
    repository.listTransactions.mockResolvedValue([txRow('t1', 30, 'starter')]);

    const res = await service.getWalletForUser('u1');

    expect(repository.createWithStarter).toHaveBeenCalledWith('u1', 30);
    expect(res.balance).toBe(30);
    expect(res.transactions[0].kind).toBe('starter');
  });

  it('survives a create race by reading the winner wallet', async () => {
    repository.findByUserId
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(wallet('w-winner', 30));
    repository.createWithStarter.mockRejectedValue(uniqueViolation());
    repository.listTransactions.mockResolvedValue([txRow('t1', 30, 'starter')]);

    const res = await service.getWalletForUser('u1');

    expect(res.balance).toBe(30);
    expect(repository.createWithStarter).toHaveBeenCalledTimes(1);
  });

  it('rethrows non-unique failures untouched', async () => {
    repository.findByUserId.mockResolvedValue(null);
    repository.createWithStarter.mockRejectedValue(new Error('db down'));

    await expect(service.getWalletForUser('u1')).rejects.toMatchObject({ message: 'db down' });
  });

  it('shapes transactions newest-first with ISO timestamps', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 28));
    repository.listTransactions.mockResolvedValue([
      txRow('t2', -5, 'debit', '2026-01-02T10:00:00Z'),
      txRow('t1', 30, 'starter', '2026-01-01T00:00:00Z'),
    ]);

    const res = await service.getWalletForUser('u1');

    expect(res.transactions.map((t) => t.id)).toEqual(['t2', 't1']);
    expect(res.transactions[0].createdAt).toBe('2026-01-02T10:00:00.000Z');
  });
});

describe('WalletService.debitForReading', () => {
  beforeEach(() => jest.clearAllMocks());

  const params = {
    userId: 'u1',
    cost: 5,
    reason: 'reading:hafez',
    idempotencyRefId: 'key-12345678',
  };

  it('debits atomically: conditional decrement + signed ledger row in one tx', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 30));
    repository.decrementIfAffordable.mockResolvedValue(true);
    repository.appendLedgerRow.mockResolvedValue(
      txRow('d1', -5, 'debit', '2026-01-02', {
        refType: 'idempotency',
        refId: params.idempotencyRefId,
      }),
    );

    const res = await service.debitForReading(params);

    expect(transactions.run).toHaveBeenCalledTimes(1);
    expect(repository.decrementIfAffordable).toHaveBeenCalledWith('w1', 5, TX);
    expect(repository.appendLedgerRow).toHaveBeenCalledWith(
      {
        walletId: 'w1',
        amount: -5,
        kind: 'debit',
        reason: 'reading:hafez',
        refType: 'idempotency',
        refId: 'key-12345678',
      },
      TX,
    );
    expect(res).toEqual({ transactionId: 'd1', amount: -5 });
  });

  it('creates the wallet (outside the debit tx, race-safe) for a first-time debit', async () => {
    repository.findByUserId.mockResolvedValue(null);
    repository.createWithStarter.mockResolvedValue(wallet('w-new', 30));
    repository.decrementIfAffordable.mockResolvedValue(true);
    repository.appendLedgerRow.mockResolvedValue(txRow('d1', -5, 'debit'));

    await service.debitForReading(params);

    expect(repository.createWithStarter).toHaveBeenCalledWith('u1', 30);
  });

  it('fails with INSUFFICIENT_COINS when the balance cannot afford the cost', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 2));
    repository.decrementIfAffordable.mockResolvedValue(false);

    await expect(service.debitForReading(params)).rejects.toMatchObject({
      code: 'INSUFFICIENT_COINS',
    });
    expect(repository.appendLedgerRow).not.toHaveBeenCalled();
  });

  it('maps a duplicate idempotency ref to DUPLICATE_REQUEST (tx rolls back)', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 30));
    repository.decrementIfAffordable.mockResolvedValue(true);
    repository.appendLedgerRow.mockRejectedValue(uniqueViolation());

    await expect(service.debitForReading(params)).rejects.toMatchObject({
      code: 'DUPLICATE_REQUEST',
    });
  });

  it('writes a debit without a ref when no idempotency key was provided', async () => {
    repository.findByUserId.mockResolvedValue(wallet('w1', 30));
    repository.decrementIfAffordable.mockResolvedValue(true);
    repository.appendLedgerRow.mockResolvedValue(txRow('d1', -5, 'debit'));

    await service.debitForReading({ ...params, idempotencyRefId: null });

    expect(repository.appendLedgerRow).toHaveBeenCalledWith(
      expect.objectContaining({ refType: null, refId: null }),
      TX,
    );
  });

  it('rejects a non-positive or non-integer cost before touching the wallet', async () => {
    for (const cost of [0, -5, 2.5]) {
      await expect(service.debitForReading({ ...params, cost })).rejects.toMatchObject({
        code: 'VALIDATION_FAILED',
      });
    }
    expect(transactions.run).not.toHaveBeenCalled();
  });
});

describe('WalletService.refundDebit', () => {
  beforeEach(() => jest.clearAllMocks());

  it('refunds a debit with a compensating row and restores the balance', async () => {
    repository.findTransactionById.mockResolvedValue(
      txRow('d1', -5, 'debit', '2026-01-02', { walletId: 'w1' }),
    );
    repository.appendLedgerRow.mockResolvedValue(
      txRow('r1', 5, 'refund', '2026-01-02', { refType: 'debit', refId: 'd1' }),
    );

    const res = await service.refundDebit('d1', 'reading:failed');

    expect(repository.appendLedgerRow).toHaveBeenCalledWith(
      {
        walletId: 'w1',
        amount: 5,
        kind: 'refund',
        reason: 'reading:failed',
        refType: 'debit',
        refId: 'd1',
      },
      TX,
    );
    expect(repository.incrementBalance).toHaveBeenCalledWith('w1', 5, TX);
    expect(res).toEqual({ transactionId: 'r1', amount: 5 });
  });

  it('is idempotent: a second refund returns the existing row, no new credit', async () => {
    repository.findTransactionById.mockResolvedValue(txRow('d1', -5, 'debit'));
    repository.appendLedgerRow.mockRejectedValue(uniqueViolation());
    repository.findByKindAndRef.mockResolvedValue(
      txRow('r1', 5, 'refund', '2026-01-02', { refType: 'debit', refId: 'd1' }),
    );

    const res = await service.refundDebit('d1', 'reading:failed');

    expect(res.transactionId).toBe('r1');
    expect(repository.incrementBalance).not.toHaveBeenCalled();
  });

  it('refuses to refund a credit or an unknown transaction', async () => {
    repository.findTransactionById.mockResolvedValue(null);
    await expect(service.refundDebit('missing', 'x')).rejects.toMatchObject({ code: 'CONFLICT' });

    repository.findTransactionById.mockResolvedValue(txRow('c1', 30, 'starter'));
    await expect(service.refundDebit('c1', 'x')).rejects.toMatchObject({ code: 'CONFLICT' });
  });
});
