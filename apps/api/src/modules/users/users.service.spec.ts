import { UsersService } from './users.service';

const prisma = {
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
};

const service = new UsersService(prisma as never);

function userRow(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: 'u1',
    telegramId: '42',
    displayName: 'از تلگرام',
    locale: 'fa',
    birthMonth: null,
    onboardingCompleted: false,
    onboardingCompletedAt: null,
    profileVersion: 0,
    personalizationOptOut: false,
    ...overrides,
  };
}

beforeEach(() => {
  jest.clearAllMocks();
  prisma.user.update.mockImplementation(({ data }: { data: Record<string, unknown> }) =>
    Promise.resolve(userRow(data)),
  );
});

describe('UsersService.upsertTelegramUser', () => {
  it('creates a new user with the Telegram-suggested name', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue(userRow());

    await service.upsertTelegramUser({
      telegramId: '42',
      displayName: 'علی',
      languageCode: 'fa',
    });

    expect(prisma.user.create).toHaveBeenCalled();
  });

  it('still refreshes the suggestion before onboarding completes', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow({ onboardingCompleted: false }));

    await service.upsertTelegramUser({
      telegramId: '42',
      displayName: 'نام جدید تلگرام',
      languageCode: null,
    });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.displayName).toBe('نام جدید تلگرام');
  });

  it('NEVER overwrites a confirmed name on later logins (scope §16)', async () => {
    prisma.user.findUnique.mockResolvedValue(
      userRow({ onboardingCompleted: true, displayName: 'علی' }),
    );

    await service.upsertTelegramUser({
      telegramId: '42',
      displayName: 'Aliakbar',
      languageCode: null,
    });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.displayName).toBeUndefined();
  });
});

describe('UsersService.completeOnboarding', () => {
  it('normalizes the name, stores the month, and completes exactly once', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow());

    const view = await service.completeOnboarding('u1', {
      displayName: '  علی   رضا  ',
      birthMonth: 'mehr',
    });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.displayName).toBe('علی رضا');
    expect(args.data.birthMonth).toBe('MEHR');
    expect(args.data.onboardingCompleted).toBe(true);
    expect(view.onboardingCompleted).toBe(true);
  });

  it('is idempotent: a repeated submit returns the stored profile untouched', async () => {
    prisma.user.findUnique.mockResolvedValue(
      userRow({ onboardingCompleted: true, displayName: 'علی', birthMonth: 'MEHR' }),
    );

    const view = await service.completeOnboarding('u1', {
      displayName: 'دیگری',
      birthMonth: 'DEY',
    });

    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(view.displayName).toBe('علی');
    expect(view.birthMonth).toBe('MEHR');
  });

  it('strips markup so a name can never smuggle instructions', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow());

    await service.completeOnboarding('u1', {
      displayName: 'علی<script>x</script>',
      birthMonth: 'MEHR',
    });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(String(args.data.displayName)).not.toContain('<');
    expect(String(args.data.displayName)).not.toContain('>');
  });

  it('rejects an empty name and an unknown month', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow());

    await expect(
      service.completeOnboarding('u1', { displayName: '   ', birthMonth: 'MEHR' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await expect(
      service.completeOnboarding('u1', { displayName: 'علی', birthMonth: 'NOPE' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
  });
});

describe('UsersService.updateProfile', () => {
  it('updates the chosen fields and bumps the profile version', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow({ onboardingCompleted: true }));

    await service.updateProfile('u1', { displayName: 'نیلوفر' });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.displayName).toBe('نیلوفر');
    expect(args.data.profileVersion).toEqual({ increment: 1 });
    expect(args.data.birthMonth).toBeUndefined();
  });

  it('switches personalization off, and says so in the profile', async () => {
    prisma.user.findUnique.mockResolvedValue(userRow({ onboardingCompleted: true }));

    const view = await service.updateProfile('u1', { personalizationOptOut: true });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.personalizationOptOut).toBe(true);
    expect(view.personalizationOptOut).toBe(true);
  });

  it('leaves personalization alone when the edit does not mention it', async () => {
    prisma.user.findUnique.mockResolvedValue(
      userRow({ onboardingCompleted: true, personalizationOptOut: true }),
    );

    await service.updateProfile('u1', { displayName: 'نیلوفر' });

    const args = prisma.user.update.mock.calls[0]?.[0] as { data: Record<string, unknown> };
    expect(args.data.personalizationOptOut).toBeUndefined();
  });

  it('throws NOT_FOUND for an unknown user', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(service.getProfile('nope')).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });
});
