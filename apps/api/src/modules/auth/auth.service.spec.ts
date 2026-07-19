import { createHmac } from 'node:crypto';
import { AuthService } from './auth.service';
import { TelegramTokenVerifier } from './telegram-token.verifier';
import { TokenService } from './token.service';

const BOT_TOKEN = '7654321:AAF-test-bot-token';

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

function signedInitData(user: Record<string, unknown>, authDate?: number): string {
  const entries: Array<[string, string]> = [
    ['auth_date', String(authDate ?? Math.floor(Date.now() / 1000))],
    ['query_id', 'AAtest'],
    ['user', JSON.stringify(user)],
  ];
  const dataCheckString = entries
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join('\n');
  const secret = createHmac('sha256', 'WebAppData').update(BOT_TOKEN).digest();
  const hash = createHmac('sha256', secret).update(dataCheckString).digest('hex');
  const params = new URLSearchParams(entries);
  params.append('hash', hash);
  return params.toString();
}

function tamperHash(initData: string): string {
  return initData.replace(/hash=(.)/, (_m, c: string) => `hash=${c === '0' ? '1' : '0'}`);
}

function makeTokenService(): TokenService {
  return new TokenService(
    { jwtPrivateKey: null, jwtPublicKey: null, tokenTtlSeconds: 3600 } as never,
    { jwtIssuer: 'fortune-app', jwtAudience: 'fortune-clients' } as never,
    { isProduction: false } as never,
    logger as never,
  );
}

describe('AuthService.loginWithTelegram', () => {
  const authConfig = { botToken: BOT_TOKEN, initDataMaxAgeSeconds: 3600 };
  const users = {
    upsertTelegramUser: jest.fn().mockImplementation(({ telegramId, displayName }) =>
      Promise.resolve({
        id: `user-${telegramId}`,
        telegramId,
        displayName,
        locale: 'fa',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    ),
  };
  let tokens: TokenService;
  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    tokens = makeTokenService();
    service = new AuthService(authConfig as never, users as never, tokens, logger as never);
  });

  it('verifies initData, upserts the tg:<id> anchor, and returns a working token', async () => {
    const res = await service.loginWithTelegram(
      signedInitData({ id: 42, first_name: 'سارا', language_code: 'fa' }),
    );

    expect(users.upsertTelegramUser).toHaveBeenCalledWith({
      telegramId: '42',
      displayName: 'سارا',
      languageCode: 'fa',
    });
    expect(res.tokenType).toBe('Bearer');
    expect(res.user.id).toBe('user-42');

    const verifier = new TelegramTokenVerifier(tokens);
    const principal = await verifier.verify(res.accessToken);
    expect(principal).toEqual({ userId: 'user-42', telegramId: '42', roles: ['user'] });
  });

  it('rejects forged initData with UNAUTHORIZED and creates no user', async () => {
    const forged = tamperHash(signedInitData({ id: 42, first_name: 'x' }));

    await expect(service.loginWithTelegram(forged)).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
    expect(users.upsertTelegramUser).not.toHaveBeenCalled();
  });

  it('rejects stale initData', async () => {
    const stale = signedInitData({ id: 42, first_name: 'x' }, Math.floor(Date.now() / 1000) - 7200);

    await expect(service.loginWithTelegram(stale)).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
  });

  it('never logs the raw initData or the user name on failure', async () => {
    const forged = tamperHash(signedInitData({ id: 42, first_name: 'محرمانه' }));
    await service.loginWithTelegram(forged).catch(() => undefined);

    const allLogged = JSON.stringify([
      logger.debug.mock.calls,
      logger.info.mock.calls,
      logger.warn.mock.calls,
      logger.error.mock.calls,
    ]);
    expect(allLogged).not.toContain('محرمانه');
    expect(allLogged).not.toContain('hash=');
  });

  it('fails as infrastructure when the bot token is missing (non-prod misconfig)', async () => {
    const broken = new AuthService(
      { botToken: null, initDataMaxAgeSeconds: 3600 } as never,
      users as never,
      tokens,
      logger as never,
    );
    await expect(broken.loginWithTelegram('anything')).rejects.toMatchObject({
      code: 'INTERNAL',
    });
  });
});
