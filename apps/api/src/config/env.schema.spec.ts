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
    expect(() =>
      validateEnv({ ...base, NODE_ENV: 'production', SWAGGER_ENABLED: 'true' }),
    ).toThrow(/CORS/);
  });
});
