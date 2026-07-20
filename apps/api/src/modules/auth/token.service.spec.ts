import { generateKeyPairSync } from 'node:crypto';
import { TokenService } from './token.service';

const logger = { debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() };

const securityConfig = { jwtIssuer: 'fortune-app', jwtAudience: 'fortune-clients' };

function makeService(overrides?: {
  privatePem?: string | null;
  publicPem?: string | null;
  isProduction?: boolean;
  ttl?: number;
}): TokenService {
  const authConfig = {
    jwtPrivateKey: overrides?.privatePem ?? null,
    jwtPublicKey: overrides?.publicPem ?? null,
    tokenTtlSeconds: overrides?.ttl ?? 3600,
  };
  const appConfig = { isProduction: overrides?.isProduction ?? false };
  return new TokenService(
    authConfig as never,
    securityConfig as never,
    appConfig as never,
    logger as never,
  );
}

describe('TokenService', () => {
  beforeEach(() => jest.clearAllMocks());

  it('signs and verifies a round-trip token with the expected claims', () => {
    const service = makeService();
    const signed = service.sign('user-1', { telegramId: '42', roles: ['user'] });

    expect(signed.expiresInSeconds).toBe(3600);
    const claims = service.verify(signed.accessToken);
    expect(claims).not.toBeNull();
    expect(claims?.sub).toBe('user-1');
    expect(claims?.tid).toBe('42');
    expect(claims?.roles).toEqual(['user']);
    expect(claims?.iss).toBe('fortune-app');
    expect(claims?.aud).toBe('fortune-clients');
  });

  it('rejects a tampered payload', () => {
    const service = makeService();
    const token = service.sign('user-1', { telegramId: '42', roles: ['user'] }).accessToken;
    const [h, p, s] = token.split('.');
    const forgedPayload = Buffer.from(
      JSON.stringify({
        ...JSON.parse(Buffer.from(p, 'base64url').toString('utf8')),
        sub: 'user-2',
      }),
    ).toString('base64url');

    expect(service.verify(`${h}.${forgedPayload}.${s}`)).toBeNull();
  });

  it('rejects a token signed by a different keypair', () => {
    const service = makeService();
    const stranger = makeService();
    const foreign = stranger.sign('user-1', { telegramId: '42', roles: ['user'] }).accessToken;

    // Each ephemeral service has its own keys — cross-verification must fail.
    expect(service.verify(foreign)).toBeNull();
  });

  it('rejects an expired token', () => {
    const service = makeService({ ttl: 1 });
    const token = service.sign('user-1', { telegramId: '42', roles: ['user'] }).accessToken;

    jest.useFakeTimers({ now: Date.now() + 120_000 });
    try {
      expect(service.verify(token)).toBeNull();
    } finally {
      jest.useRealTimers();
    }
  });

  it('rejects structural garbage without throwing', () => {
    const service = makeService();
    expect(service.verify('')).toBeNull();
    expect(service.verify('a.b')).toBeNull();
    expect(service.verify('a.b.c')).toBeNull();
    expect(service.verify('..')).toBeNull();
  });

  it('rejects a token whose header claims a different algorithm', () => {
    const service = makeService();
    const token = service.sign('user-1', { telegramId: '42', roles: ['user'] }).accessToken;
    const [, p, s] = token.split('.');
    const noneHeader = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString(
      'base64url',
    );

    expect(service.verify(`${noneHeader}.${p}.${s}`)).toBeNull();
    expect(service.verify(`${noneHeader}.${p}.`)).toBeNull();
  });

  it('uses a configured ed25519 keypair instead of ephemeral keys', () => {
    const pair = generateKeyPairSync('ed25519');
    const service = makeService({
      privatePem: pair.privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
      publicPem: pair.publicKey.export({ type: 'spki', format: 'pem' }).toString(),
    });

    const token = service.sign('user-9', { telegramId: '9', roles: ['user'] }).accessToken;
    expect(service.verify(token)?.sub).toBe('user-9');
    expect(logger.info).toHaveBeenCalledWith('auth.keys.loaded', { alg: 'EdDSA' });
    expect(logger.warn).not.toHaveBeenCalled();
  });

  it('supports RSA keys as RS256', () => {
    const pair = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const service = makeService({
      privatePem: pair.privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
      publicPem: pair.publicKey.export({ type: 'spki', format: 'pem' }).toString(),
    });

    const token = service.sign('user-r', { telegramId: '1', roles: ['user'] }).accessToken;
    const header = JSON.parse(Buffer.from(token.split('.')[0], 'base64url').toString('utf8')) as {
      alg: string;
    };
    expect(header.alg).toBe('RS256');
    expect(service.verify(token)?.sub).toBe('user-r');
  });

  it('refuses to boot in production without a configured keypair', () => {
    expect(() => makeService({ isProduction: true })).toThrow(/production/);
  });

  it('warns loudly when running on ephemeral keys outside production', () => {
    makeService();
    expect(logger.warn).toHaveBeenCalledWith(
      'auth.keys.ephemeral',
      expect.objectContaining({ alg: 'EdDSA' }),
    );
  });
});
