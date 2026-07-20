import { TelegramTokenVerifier } from './telegram-token.verifier';
import type { AccessTokenClaims } from './token.service';

function makeVerifier(verifyImpl: (token: string) => AccessTokenClaims | null) {
  const tokens = { verify: jest.fn(verifyImpl) };
  const verifier = new TelegramTokenVerifier(tokens as never);
  return { verifier, tokens };
}

describe('TelegramTokenVerifier', () => {
  it('maps valid claims onto an AuthenticatedPrincipal', async () => {
    const claims: AccessTokenClaims = {
      iss: 'fortune-app',
      aud: 'fortune-clients',
      sub: 'user-1',
      tid: '42',
      roles: ['user'],
      iat: 0,
      exp: 999_999_999,
    };
    const { verifier, tokens } = makeVerifier(() => claims);

    const principal = await verifier.verify('some.jwt.token');

    expect(tokens.verify).toHaveBeenCalledWith('some.jwt.token');
    expect(principal).toEqual({
      userId: 'user-1',
      telegramId: '42',
      roles: ['user'],
    });
  });

  it('returns null when TokenService rejects the token', async () => {
    const { verifier } = makeVerifier(() => null);

    expect(await verifier.verify('garbage')).toBeNull();
  });

  it('preserves multiple roles without dropping or reordering them', async () => {
    const claims: AccessTokenClaims = {
      iss: 'fortune-app',
      aud: 'fortune-clients',
      sub: 'user-2',
      tid: '7',
      roles: ['user', 'admin'],
      iat: 0,
      exp: 999_999_999,
    };
    const { verifier } = makeVerifier(() => claims);

    const principal = await verifier.verify('another.jwt.token');

    expect(principal?.roles).toEqual(['user', 'admin']);
  });

  it('never calls TokenService.verify more than once per verify() call', async () => {
    const { verifier, tokens } = makeVerifier(() => null);

    await verifier.verify('token-a');
    await verifier.verify('token-b');

    expect(tokens.verify).toHaveBeenCalledTimes(2);
    expect(tokens.verify).toHaveBeenNthCalledWith(1, 'token-a');
    expect(tokens.verify).toHaveBeenNthCalledWith(2, 'token-b');
  });
});
