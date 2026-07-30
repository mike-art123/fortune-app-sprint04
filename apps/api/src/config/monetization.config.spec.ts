import { MonetizationConfig } from './monetization.config';

function makeConfig(env: Record<string, unknown>): MonetizationConfig {
  return new MonetizationConfig({ get: (key: string) => env[key] } as never);
}

describe('MonetizationConfig.isPlatformUnlimited', () => {
  it('exempts android by default and nothing else', () => {
    const config = makeConfig({});

    expect(config.isPlatformUnlimited('android')).toBe(true);
    expect(config.isPlatformUnlimited('web')).toBe(false);
    expect(config.isPlatformUnlimited(null)).toBe(false);
    expect(config.isPlatformUnlimited(undefined)).toBe(false);
  });

  it('normalizes case and whitespace on both sides', () => {
    const config = makeConfig({ ACCESS_UNLIMITED_PLATFORMS: ' Android , iOS ' });

    expect(config.isPlatformUnlimited('ANDROID')).toBe(true);
    expect(config.isPlatformUnlimited(' ios ')).toBe(true);
    expect(config.isPlatformUnlimited('web')).toBe(false);
  });

  it('an empty list turns the exemption off everywhere', () => {
    const config = makeConfig({ ACCESS_UNLIMITED_PLATFORMS: '' });

    expect(config.isPlatformUnlimited('android')).toBe(false);
  });
});
