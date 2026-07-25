import { orderProviders } from './provider-ordering';

const configured = new Set(['adsgram', 'monetag']);
const isConfigured = (p: string): boolean => configured.has(p);

describe('orderProviders', () => {
  it('keeps the configured priority when everyone is healthy', () => {
    const order = orderProviders(['adsgram', 'monetag'], isConfigured, [], 3);
    expect(order).toEqual(['adsgram', 'monetag']);
  });

  it('drops providers that are not configured', () => {
    const order = orderProviders(['adsgram', 'monetag'], (p) => p === 'monetag', [], 3);
    expect(order).toEqual(['monetag']);
  });

  it('demotes (never removes) a provider in cooldown', () => {
    const health = [{ provider: 'adsgram', recentConsecutiveFailures: 3 }];
    const order = orderProviders(['adsgram', 'monetag'], isConfigured, health, 3);
    expect(order).toEqual(['monetag', 'adsgram']);
  });

  it('keeps a provider below the failure threshold in place', () => {
    const health = [{ provider: 'adsgram', recentConsecutiveFailures: 2 }];
    const order = orderProviders(['adsgram', 'monetag'], isConfigured, health, 3);
    expect(order).toEqual(['adsgram', 'monetag']);
  });

  it('returns empty when nothing is configured', () => {
    const order = orderProviders(['adsgram', 'monetag'], () => false, [], 3);
    expect(order).toEqual([]);
  });
});
