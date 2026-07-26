import { buildDigest, digestFingerprint, type ReadingMoment } from './history-digest';
import { narrativeFrom, narrativeText } from './history-narrative';

const TZ = 'Asia/Tehran';
const NOW = new Date('2026-07-26T12:00:00.000Z');

/** Tehran is UTC+3:30, so 05:30Z is 09:00 local — the morning bucket. */
function at(iso: string, fortuneId: string, id: string): ReadingMoment {
  return { id, fortuneId, createdAt: new Date(iso) };
}

function digestOf(moments: ReadingMoment[], range: 'last7' | 'last30' = 'last30') {
  return buildDigest({ moments, range, now: NOW, timeZone: TZ });
}

/**
 * A summary is arithmetic about somebody's own visits. It may count, it may
 * compare with last time, and it may not do anything else — no prediction, no
 * judgement, and nothing it cannot show the receipts for.
 */
describe('history digest', () => {
  it('counts only the window asked for, and compares with the one before', () => {
    const digest = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-10T05:30:00.000Z', 'hafez', 'r2'),
      at('2026-06-20T05:30:00.000Z', 'tarot', 'r3'), // previous window
      at('2026-01-01T05:30:00.000Z', 'tarot', 'r4'), // outside both
    ]);

    expect(digest.total).toBe(2);
    expect(digest.previousTotal).toBe(1);
    expect(digest.sourceIds).toEqual(['r1', 'r2']);
  });

  it('names a favourite by count, and never one that was only read once', () => {
    const many = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-19T05:30:00.000Z', 'hafez', 'r2'),
      at('2026-07-18T05:30:00.000Z', 'tarot', 'r3'),
    ]);
    expect(many.favourite).toEqual({ fortuneId: 'hafez', titleFa: 'فال حافظ', count: 2 });
    expect(narrativeFrom(many)).toContain('بیشتر از همه سراغ فال حافظ رفتی (۲ بار).');

    const once = digestOf([at('2026-07-20T05:30:00.000Z', 'hafez', 'r1')]);
    expect(once.favourite?.count).toBe(1);
    expect(narrativeText(once)).not.toContain('بیشتر از همه');
  });

  it('names a time of day only when there is an outright habit', () => {
    // Three mornings (09:00 Tehran) — a habit.
    const mornings = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-19T05:30:00.000Z', 'hafez', 'r2'),
      at('2026-07-18T05:30:00.000Z', 'hafez', 'r3'),
    ]);
    expect(mornings.dayPart).toBe('morning');

    // One morning, one night — a tie says nothing.
    const tied = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-19T20:30:00.000Z', 'hafez', 'r2'),
    ]);
    expect(tied.dayPart).toBeNull();
    expect(narrativeText(tied)).not.toContain('بیشترشان');
  });

  it('counts distinct local days, not readings', () => {
    const digest = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-20T12:30:00.000Z', 'tarot', 'r2'),
      at('2026-07-19T05:30:00.000Z', 'hafez', 'r3'),
    ]);
    expect(digest.total).toBe(3);
    expect(digest.activeDays).toBe(2);
  });

  it('calls a fortune new only when the previous window never saw it', () => {
    const digest = digestOf([
      at('2026-07-20T05:30:00.000Z', 'tarot', 'r1'),
      at('2026-07-19T05:30:00.000Z', 'hafez', 'r2'),
      at('2026-06-20T05:30:00.000Z', 'hafez', 'r3'), // previous window
    ]);
    expect(digest.firstTime.map((entry) => entry.fortuneId)).toEqual(['tarot']);
    expect(narrativeFrom(digest)).toContain('و تاروت را این دوره تازه آزمودی.');
  });

  it('says nothing at all rather than something empty', () => {
    const digest = digestOf([]);
    expect(digest.total).toBe(0);
    expect(narrativeFrom(digest)).toEqual(['در سی روز گذشته فالی نگرفته‌ای.']);
  });

  it('compares in both directions, and says so plainly', () => {
    const fewer = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-06-20T05:30:00.000Z', 'hafez', 'r2'),
      at('2026-06-21T05:30:00.000Z', 'hafez', 'r3'),
    ]);
    expect(narrativeFrom(fewer)[0]).toBe('در سی روز گذشته ۱ فال گرفتی؛ ۱ تا کمتر از دورهٔ پیش.');

    const same = digestOf([
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-06-20T05:30:00.000Z', 'hafez', 'r2'),
    ]);
    expect(narrativeFrom(same)[0]).toBe('در سی روز گذشته ۱ فال گرفتی؛ درست به‌اندازهٔ دورهٔ پیش.');
  });

  it('changes its fingerprint the moment a reading appears or disappears', () => {
    const two = [
      at('2026-07-20T05:30:00.000Z', 'hafez', 'r1'),
      at('2026-07-19T05:30:00.000Z', 'tarot', 'r2'),
    ];
    const one = [at('2026-07-20T05:30:00.000Z', 'hafez', 'r1')];

    expect(digestFingerprint(digestOf(two))).not.toBe(digestFingerprint(digestOf(one)));
    // Same readings, same fingerprint — a cache may be trusted then.
    expect(digestFingerprint(digestOf(two))).toBe(digestFingerprint(digestOf([...two])));
  });
});
