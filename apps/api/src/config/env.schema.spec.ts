import { validateEnv } from './env.schema';

const base = {
  DATABASE_URL: 'postgresql://u:p@localhost:5432/db',
  JWT_ISSUER: 'fortune-app',
};

describe('env schema', () => {
  it('applies defaults for a minimal valid env', () => {
    const env = validateEnv({ ...base });
    expect(env.APP_PORT).toBe(3000);
    expect(env.API_PREFIX).toBe('api');
    expect(env.NODE_ENV).toBe('development');
  });

  it('fails fast without DATABASE_URL', () => {
    expect(() => validateEnv({})).toThrow(/Invalid environment/);
  });

  it('production requires an explicit CORS allowlist when swagger is on', () => {
    expect(() => validateEnv({ ...base, NODE_ENV: 'production', SWAGGER_ENABLED: 'true' })).toThrow(
      /CORS/,
    );
  });

  const productionBase = {
    ...base,
    NODE_ENV: 'production',
    SWAGGER_ENABLED: 'false',
    CORS_ALLOWED_ORIGINS: 'https://t.me',
    TELEGRAM_BOT_TOKEN: '123456:AA-token',
    JWT_PRIVATE_KEY: 'private',
    JWT_PUBLIC_KEY: 'public',
  };

  it('production refuses to boot without an LLM endpoint (no mock readings in prod)', () => {
    expect(() => validateEnv({ ...productionBase })).toThrow(/LLM_BASE_URL/);
  });

  it('accepts a complete production env once the LLM endpoint is configured', () => {
    const complete = {
      ...productionBase,
      LLM_BASE_URL: 'https://api.openai.com/v1',
      LLM_API_KEY: 'sk-real-key',
    };
    expect(() => validateEnv(complete)).not.toThrow();
  });
});
