/**
 * What we are willing to say to someone, and the rules that decide whether we
 * say it at all (scope §7).
 *
 * Everything in this file is pure: given the same clock, the same preferences
 * and the same recent history, it returns the same answer. That is deliberate —
 * a notification is the one feature that reaches a person when they are not
 * looking, so the decision has to be inspectable, testable, and boring.
 */

export const NOTIFICATION_KINDS = ['dailyFortune', 'streakReminder', 'weeklySummary'] as const;
export type NotificationKind = (typeof NOTIFICATION_KINDS)[number];

export interface NotificationPreferenceView {
  dailyFortune: boolean;
  streakReminder: boolean;
  weeklySummary: boolean;
  /** Local hours. `from` may be greater than `to` — quiet hours cross midnight. */
  quietFromHour: number;
  quietToHour: number;
  dailyCap: number;
  timeZone: string;
  mutedUntil: string | null;
}

export const DEFAULT_PREFERENCES: NotificationPreferenceView = {
  dailyFortune: true,
  streakReminder: true,
  weeklySummary: false,
  quietFromHour: 22,
  quietToHour: 8,
  dailyCap: 1,
  timeZone: 'Asia/Tehran',
  mutedUntil: null,
};

/** One message, already decided on. The text is Persian and final. */
export interface NotificationPlan {
  kind: NotificationKind;
  text: string;
}

/** Everything the decision is allowed to look at. */
export interface NotificationContext {
  now: Date;
  prefs: NotificationPreferenceView;
  /** When this reader last opened a fortune, or null if they never have. */
  lastReadingAt: Date | null;
  /** Kinds already sent today, in this reader's own timezone. */
  sentToday: readonly NotificationKind[];
  /** The reader's stored UI language; undefined means Persian. */
  locale?: string;
}

/**
 * The copy. Short, calm, and never about anybody in particular: no name, no
 * birth month, and never a line from a reading. A message that lands on a lock
 * screen is read by whoever is holding the phone.
 */
const FA_TEXTS: Record<NotificationKind, string> = {
  dailyFortune: 'بیا که فالِ روزتو بگیرم، ببینی امروز چی در انتظارته',
  streakReminder: 'چند روزی است سراغ فالی نرفته‌ای. هر وقت خواستی، همین‌جاست.',
  weeklySummary: 'یک نگاه به هفته‌ای که گذشت در تاریخچه‌ات آماده است.',
};

const TEXTS: Record<string, Record<NotificationKind, string>> = {
  fa: FA_TEXTS,
  en: {
    dailyFortune: 'Come, let me read your fortune for today — see what awaits you.',
    streakReminder:
      'It has been a few days since your last fortune. It is right here whenever you wish.',
    weeklySummary: 'A look at your past week is ready in your history.',
  },
  ar: {
    dailyFortune: 'تعال أقرأ لك فأل يومك، لترى ما ينتظرك اليوم.',
    streakReminder: 'مرت أيام منذ آخر فأل لك. متى شئت، فهو هنا.',
    weeklySummary: 'نظرة على أسبوعك الماضي جاهزة في سجلّك.',
  },
  tr: {
    dailyFortune: 'Gel, günlük falına bakayım — bugün seni neler bekliyor gör.',
    streakReminder: 'Birkaç gündür fala uğramadın. Ne zaman istersen, burada.',
    weeklySummary: 'Geçen haftana bir bakış geçmişinde hazır.',
  },
};

/** The copy for one kind, in the reader's own language (fa is the default). */
export function notificationText(kind: NotificationKind, locale?: string): string {
  const table = (locale ? TEXTS[locale] : undefined) ?? FA_TEXTS;
  return table[kind];
}

/** Local wall-clock fields, from the server clock and the reader's zone. */
export function localFields(
  at: Date,
  timeZone: string,
): {
  dateKey: string;
  hour: number;
  weekday: string;
} {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    weekday: 'short',
  }).formatToParts(at);
  const get = (type: string): string => parts.find((p) => p.type === type)?.value ?? '';
  return {
    dateKey: `${get('year')}-${get('month')}-${get('day')}`,
    hour: Number(get('hour')),
    weekday: get('weekday'),
  };
}

/**
 * True while the reader asked not to be disturbed. Quiet hours are allowed to
 * cross midnight, which is the normal case: 22 → 8.
 */
export function isQuiet(hour: number, fromHour: number, toHour: number): boolean {
  if (fromHour === toHour) return false;
  return fromHour < toHour ? hour >= fromHour && hour < toHour : hour >= fromHour || hour < toHour;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/** How many whole days since the last reading; null when there never was one. */
function daysSince(now: Date, last: Date | null): number | null {
  if (last === null) return null;
  return Math.floor((now.getTime() - last.getTime()) / DAY_MS);
}

/**
 * What to send this reader right now — usually nothing (scope §7).
 *
 * The order below is the priority order, and the daily cap cuts the list, so
 * when only one message is allowed it is the most useful one. Every gate is a
 * reason not to send: muted, quiet hours, cap reached, already sent today,
 * switched off, or simply nothing worth saying.
 */
export function decideNotifications(context: NotificationContext): NotificationPlan[] {
  const { now, prefs, lastReadingAt, sentToday, locale } = context;

  if (prefs.mutedUntil !== null && new Date(prefs.mutedUntil).getTime() > now.getTime()) {
    return [];
  }

  const { hour, weekday } = localFields(now, prefs.timeZone);
  if (isQuiet(hour, prefs.quietFromHour, prefs.quietToHour)) return [];

  const remaining = prefs.dailyCap - sentToday.length;
  if (remaining <= 0) return [];

  const gap = daysSince(now, lastReadingAt);
  const readToday =
    lastReadingAt !== null &&
    localFields(lastReadingAt, prefs.timeZone).dateKey === localFields(now, prefs.timeZone).dateKey;

  const already = new Set<NotificationKind>(sentToday);
  const plans: NotificationPlan[] = [];

  const consider = (kind: NotificationKind, when: boolean): void => {
    if (!when || already.has(kind) || plans.length >= remaining) return;
    plans.push({ kind, text: notificationText(kind, locale) });
  };

  // A real absence is the most useful thing we could say, so it goes first
  // when the cap allows only one message. Day three, then once a week — an
  // absence is not an invitation to ask every morning.
  consider('streakReminder', prefs.streakReminder && gap !== null && gap >= 3 && gap % 7 === 3);

  // Today's fortune, once the day has properly started and only when they have
  // not already read something today.
  consider('dailyFortune', prefs.dailyFortune && hour >= 8 && !readToday);

  // The week's look-back, on the Persian week's last day.
  consider('weeklySummary', prefs.weeklySummary && weekday === 'Fri');

  return plans;
}
