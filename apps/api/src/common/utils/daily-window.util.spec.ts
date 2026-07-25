import { dateKeyFor, nextResetAt } from './daily-window.util';

describe('daily-window util', () => {
  describe('dateKeyFor', () => {
    it('buckets by the configured timezone, not UTC', () => {
      // 20:30Z is already the next calendar day in Tehran (+03:30).
      const instant = new Date('2026-07-24T20:30:00Z');
      expect(dateKeyFor(instant, 'Asia/Tehran')).toBe('2026-07-25');
      expect(dateKeyFor(instant, 'UTC')).toBe('2026-07-24');
    });

    it('does not roll over one minute before local midnight', () => {
      const instant = new Date('2026-07-24T20:29:00Z'); // 23:59 in Tehran
      expect(dateKeyFor(instant, 'Asia/Tehran')).toBe('2026-07-24');
    });
  });

  describe('nextResetAt', () => {
    it('returns the next local midnight as a UTC instant (Tehran)', () => {
      const now = new Date('2026-07-24T10:00:00Z'); // 13:30 in Tehran
      expect(nextResetAt(now, 'Asia/Tehran').toISOString()).toBe(
        '2026-07-24T20:30:00.000Z',
      );
    });

    it('rolls to the following day when already past local midnight', () => {
      const now = new Date('2026-07-24T21:00:00Z'); // 00:30 next day in Tehran
      expect(nextResetAt(now, 'Asia/Tehran').toISOString()).toBe(
        '2026-07-25T20:30:00.000Z',
      );
    });

    it('matches UTC midnight when the zone is UTC', () => {
      const now = new Date('2026-07-24T10:00:00Z');
      expect(nextResetAt(now, 'UTC').toISOString()).toBe(
        '2026-07-25T00:00:00.000Z',
      );
    });
  });
});
