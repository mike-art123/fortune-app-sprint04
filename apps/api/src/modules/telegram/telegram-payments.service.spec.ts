import { TelegramPaymentsService } from './telegram-payments.service';

const prisma = {
  subscription: {
    findUnique: jest.fn(),
    upsert: jest.fn(),
  },
  user: {
    findUnique: jest.fn(),
  },
};

const bot = {
  api: jest.fn(),
};

const vip = {
  plans: [
    { id: 'monthly', titleFa: 'عضویت یک‌ماهه', stars: 250, days: 30 },
    { id: 'annual', titleFa: 'عضویت یک‌ساله', stars: 2000, days: 365 },
  ],
  planById(id: string) {
    return this.plans.find((p) => p.id === id) ?? null;
  },
};

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

const service = new TelegramPaymentsService(
  prisma as never,
  bot as never,
  vip as never,
  logger as never,
);

const NOW = new Date('2026-07-25T10:00:00Z');

function resetMocks(): void {
  jest.clearAllMocks();
  prisma.subscription.findUnique.mockResolvedValue(null);
  prisma.subscription.upsert.mockResolvedValue({});
  prisma.user.findUnique.mockResolvedValue({ id: 'u1', telegramId: '42' });
  bot.api.mockResolvedValue({ ok: true, result: 'https://t.me/invoice/xyz' });
}

describe('TelegramPaymentsService.createInvoiceLink', () => {
  beforeEach(resetMocks);

  it('creates a Stars (XTR) invoice bound to user and plan', async () => {
    const res = await service.createInvoiceLink('u1', 'monthly');

    expect(res.link).toBe('https://t.me/invoice/xyz');
    const [method, body] = bot.api.mock.calls[0] as [string, Record<string, unknown>];
    expect(method).toBe('createInvoiceLink');
    expect(body.currency).toBe('XTR');
    expect(body.prices).toEqual([{ label: 'عضویت یک‌ماهه', amount: 250 }]);
    expect(String(body.payload)).toMatch(/^vip:u1:monthly:/);
  });

  it('rejects an unknown plan', async () => {
    await expect(service.createInvoiceLink('u1', 'weekly')).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
    expect(bot.api).not.toHaveBeenCalled();
  });

  it('surfaces a retryable failure when Telegram refuses', async () => {
    bot.api.mockResolvedValue({ ok: false, description: 'nope' });

    await expect(service.createInvoiceLink('u1', 'monthly')).rejects.toMatchObject({
      code: 'INTERNAL',
    });
  });
});

describe('TelegramPaymentsService pre-checkout', () => {
  beforeEach(resetMocks);

  it('approves a valid pre_checkout_query', async () => {
    await service.handleUpdate({
      pre_checkout_query: {
        id: 'q1',
        currency: 'XTR',
        total_amount: 250,
        invoice_payload: 'vip:u1:monthly:abc',
      },
    });

    const [method, body] = bot.api.mock.calls[0] as [string, Record<string, unknown>];
    expect(method).toBe('answerPreCheckoutQuery');
    expect(body.ok).toBe(true);
  });

  it('refuses when the amount does not match the plan', async () => {
    await service.handleUpdate({
      pre_checkout_query: {
        id: 'q1',
        currency: 'XTR',
        total_amount: 1,
        invoice_payload: 'vip:u1:monthly:abc',
      },
    });

    const [, body] = bot.api.mock.calls[0] as [string, Record<string, unknown>];
    expect(body.ok).toBe(false);
  });

  it('refuses a malformed payload', async () => {
    await service.handleUpdate({
      pre_checkout_query: {
        id: 'q1',
        currency: 'XTR',
        total_amount: 250,
        invoice_payload: 'hack:u1:monthly:abc',
      },
    });

    const [, body] = bot.api.mock.calls[0] as [string, Record<string, unknown>];
    expect(body.ok).toBe(false);
  });
});

describe('TelegramPaymentsService successful payment', () => {
  beforeEach(resetMocks);

  const paidMessage = (chargeId: string) => ({
    message: {
      from: { id: 42 },
      successful_payment: {
        currency: 'XTR',
        total_amount: 250,
        invoice_payload: 'vip:u1:monthly:abc',
        telegram_payment_charge_id: chargeId,
      },
    },
  });

  it('activates a fresh subscription for 30 days', async () => {
    await service.handleUpdate(paidMessage('ch-1'));

    const args = prisma.subscription.upsert.mock.calls[0]?.[0] as {
      create: { currentPeriodEnd: Date; platformTransactionId: string };
    };
    expect(args.create.platformTransactionId).toBe('ch-1');
    expect(args.create.currentPeriodEnd.getTime()).toBeGreaterThan(Date.now());
  });

  it('extends an active subscription from its current end', async () => {
    const end = new Date(NOW.getTime() + 5 * 24 * 3600 * 1000);
    prisma.subscription.findUnique.mockResolvedValue({
      userId: 'u1',
      plan: 'monthly',
      status: 'active',
      currentPeriodEnd: end,
      platformTransactionId: 'ch-0',
    });

    await service.handleUpdate(paidMessage('ch-2'));

    const args = prisma.subscription.upsert.mock.calls[0]?.[0] as {
      update: { currentPeriodEnd: Date };
    };
    const expected = end.getTime() + 30 * 24 * 3600 * 1000;
    expect(args.update.currentPeriodEnd.getTime()).toBe(expected);
  });

  it('ignores a replayed charge id (webhook retry)', async () => {
    prisma.subscription.findUnique.mockResolvedValue({
      userId: 'u1',
      plan: 'monthly',
      status: 'active',
      currentPeriodEnd: new Date('2026-08-25T10:00:00Z'),
      platformTransactionId: 'ch-1',
    });

    await service.handleUpdate(paidMessage('ch-1'));

    expect(prisma.subscription.upsert).not.toHaveBeenCalled();
  });

  it('refuses a payer that does not match the payload user', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', telegramId: '999' });

    await service.handleUpdate(paidMessage('ch-3'));

    expect(prisma.subscription.upsert).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalledWith(
      'telegram.payment.payer_mismatch',
      expect.objectContaining({ userId: 'u1' }),
    );
  });
});
