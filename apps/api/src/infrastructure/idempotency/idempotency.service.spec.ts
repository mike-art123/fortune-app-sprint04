import { IdempotencyService } from './idempotency.service';

describe('idempotency fingerprint', () => {
  it('is stable for identical payloads', () => {
    expect(IdempotencyService.fingerprint({ a: 1 })).toBe(IdempotencyService.fingerprint({ a: 1 }));
  });
  it('differs for different payloads', () => {
    expect(IdempotencyService.fingerprint({ a: 1 })).not.toBe(
      IdempotencyService.fingerprint({ a: 2 }),
    );
  });
});
