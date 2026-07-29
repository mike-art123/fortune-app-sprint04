import {
  DEFAULT_PREFERENCES,
  decideNotifications,
  isQuiet,
  localFields,
  type NotificationKind,
  type NotificationPreferenceView,
} from './notification-plan';

/** Tehran is UTC+3:30, so 05:30Z is 09:00 local and 06:30Z is 10:00. */
function at(iso: string): Date {
  return new Date(iso);
}

function prefs(overrides: Partial<NotificationPreferenceView> = {}): NotificationPreferenceView {
  return { ...DEFAULT_PREFERENCES, ...overrides };
}

function kinds(
  now: Date,
  lastReadingAt: Date | null,
  overrides: Partial<NotificationPreferenceView> = {},
  sentToday: NotificationKind[] = [],
): NotificationKind[] {
  return decideNotifications({
    now,
    prefs: prefs(overrides),
    lastReadingAt,
    sentToday,
  }).map((plan) => plan.kind);
}

/**
 * A notification reaches somebody who is not looking at their phone for our
 * sake. Every test below is a reason not to send one.
 */
describe('notification rules', () => {
  it('says nothing at all during quiet hours', () => {
    // 23:30Z is 03:00 next day in Tehran — the middle of the night.
    expect(kinds(at('2026-07-26T23:30:00.000Z'), at('2026-07-20T05:30:00.000Z'))).toEqual([]);
  });

  it('lets quiet hours cross midnight, and lets them be switched off', () => {
    expect(isQuiet(23, 22, 8)).toBe(true);
    expect(isQuiet(3, 22, 8)).toBe(true);
    expect(isQuiet(9, 22, 8)).toBe(false);
    expect(isQuiet(22, 22, 8)).toBe(true);
    expect(isQuiet(8, 22, 8)).toBe(false);
    // A window of zero width silences nothing.
    expect(isQuiet(4, 0, 0)).toBe(false);
  });

  it('offers today’s fortune only after the day has started', () => {
    // 04:30Z is 08:00 local: the quiet night has just ended, so the day begins.
    expect(kinds(at('2026-07-26T04:30:00.000Z'), null)).toEqual(['dailyFortune']);
    expect(kinds(at('2026-07-26T06:30:00.000Z'), null)).toEqual(['dailyFortune']);
    // 03:30Z is 07:00 local: still inside the quiet night, so nothing at all.
    expect(kinds(at('2026-07-26T03:30:00.000Z'), null)).toEqual([]);
  });

  it('never suggests a fortune to someone who already read one today', () => {
    expect(kinds(at('2026-07-26T06:30:00.000Z'), at('2026-07-26T05:00:00.000Z'))).toEqual([]);
    // Yesterday does not count as today, even a few hours ago.
    expect(kinds(at('2026-07-26T06:30:00.000Z'), at('2026-07-25T19:00:00.000Z'))).toEqual([
      'dailyFortune',
    ]);
  });

  it('nudges after a real absence, then only once a week', () => {
    const now = at('2026-07-26T06:30:00.000Z');
    expect(kinds(now, at('2026-07-23T06:00:00.000Z'))).toEqual(['streakReminder']);
    // Day four is not day three: an absence is not asked about every morning.
    expect(kinds(now, at('2026-07-22T06:00:00.000Z'))).toEqual(['dailyFortune']);
    // Day ten comes round again.
    expect(kinds(now, at('2026-07-16T06:00:00.000Z'))).toEqual(['streakReminder']);
  });

  it('keeps the most useful message when only one is allowed', () => {
    const now = at('2026-07-31T06:30:00.000Z'); // a Friday
    const both = kinds(now, at('2026-07-28T06:00:00.000Z'), { weeklySummary: true, dailyCap: 2 });
    expect(both).toEqual(['streakReminder', 'dailyFortune']);

    const one = kinds(now, at('2026-07-28T06:00:00.000Z'), { weeklySummary: true });
    expect(one).toEqual(['streakReminder']);
  });

  it('offers the week’s look-back only on the last day of the week', () => {
    const friday = at('2026-07-31T06:30:00.000Z');
    const saturday = at('2026-08-01T06:30:00.000Z');
    expect(localFields(friday, 'Asia/Tehran').weekday).toBe('Fri');

    // Read today, so the daily message is not due and the summary is what is
    // left to say.
    expect(kinds(friday, at('2026-07-31T05:00:00.000Z'), { weeklySummary: true })).toEqual([
      'weeklySummary',
    ]);
    expect(kinds(saturday, at('2026-08-01T05:00:00.000Z'), { weeklySummary: true })).toEqual([]);
  });

  it('respects the daily cap, and a cap of zero means silence', () => {
    const now = at('2026-07-26T06:30:00.000Z');
    expect(kinds(now, null, {}, ['dailyFortune'])).toEqual([]);
    expect(kinds(now, null, { dailyCap: 0 })).toEqual([]);
  });

  it('says nothing while muted, and resumes by itself afterwards', () => {
    const now = at('2026-07-26T06:30:00.000Z');
    expect(kinds(now, null, { mutedUntil: '2026-08-01T00:00:00.000Z' })).toEqual([]);
    expect(kinds(now, null, { mutedUntil: '2026-07-25T00:00:00.000Z' })).toEqual(['dailyFortune']);
  });

  it('sends nothing that was switched off', () => {
    const now = at('2026-07-26T06:30:00.000Z');
    expect(kinds(now, at('2026-07-23T06:00:00.000Z'), { streakReminder: false })).toEqual([
      'dailyFortune',
    ]);
    expect(
      kinds(now, at('2026-07-23T06:00:00.000Z'), {
        streakReminder: false,
        dailyFortune: false,
      }),
    ).toEqual([]);
  });

  it('never puts anything personal in the words it sends', () => {
    const plans = decideNotifications({
      now: at('2026-07-26T06:30:00.000Z'),
      prefs: prefs(),
      lastReadingAt: null,
      sentToday: [],
    });
    for (const plan of plans) {
      expect(plan.text).not.toMatch(/[A-Za-z]/); // Persian only, no ids or urls
      expect(plan.text.length).toBeLessThan(120);
    }
  });

  it('reads the clock in the reader’s own zone, not the server’s', () => {
    const instant = at('2026-07-26T21:00:00.000Z');
    expect(localFields(instant, 'Asia/Tehran').hour).toBe(0);
    expect(localFields(instant, 'UTC').hour).toBe(21);

    // The same instant, two readers: midnight in Tehran is inside their quiet
    // hours, while 21:00 in London is still their evening.
    expect(kinds(instant, null, { timeZone: 'Asia/Tehran' })).toEqual([]);
    expect(kinds(instant, null, { timeZone: 'UTC' })).toEqual(['dailyFortune']);
  });
});
