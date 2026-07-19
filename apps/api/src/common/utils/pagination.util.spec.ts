import { decodeCursor, encodeCursor } from './pagination.util';

describe('cursor pagination', () => {
  it('round-trips values opaquely', () => {
    const cursor = encodeCursor('clx123');
    expect(cursor).not.toContain('clx123');
    expect(decodeCursor(cursor)).toBe('clx123');
  });
  it('rejects malformed cursors safely', () => {
    expect(decodeCursor('%%%%')).toBeUndefined();
    expect(decodeCursor(undefined)).toBeUndefined();
  });

  it('rejects garbage that decodes leniently but was never encoded by us', () => {
    // Node ignores invalid base64url characters, so this yields non-empty
    // bytes — the round-trip check must still reject it.
    expect(decodeCursor('!!!not-base64url!!!')).toBeUndefined();
    expect(decodeCursor('💥💥💥')).toBeUndefined();
  });
});
