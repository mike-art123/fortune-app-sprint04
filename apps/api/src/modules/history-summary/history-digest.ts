import { FORTUNE_CATALOG } from '../readings/fortune-catalog';
import type { ReadingMoment } from '../readings/readings.repository';

// The shape a summary counts is a projection of the readings table, so it is
// declared once there and only re-exported here for the callers of this file.
export type { ReadingMoment };

/**
 * The windows a reader may look back over (scope §6). Deliberately few: a
 * summary is meant to be glanced at, not configured.
 */
export const SUMMARY_RANGES = ['last7', 'last30', 'last90'] as const;
export type SummaryRange = (typeof SUMMARY_RANGES)[number];

export const RANGE_DAYS: Record<SummaryRange, number> = {
  last7: 7,
  last30: 30,
  last90: 90,
};

export interface FortuneTally {
  fortuneId: string;
  titleFa: string;
  count: number;
}

/** The four parts of a day this app recognises — the same boundaries the
 * mobile recommendation rules use (`dayPartOf`), so the two never disagree
 * about what "evening" means. */
export const DAY_PARTS = ['morning', 'noon', 'evening', 'night'] as const;
export type DayPart = (typeof DAY_PARTS)[number];

export interface HistoryDigest {
  range: SummaryRange;
  /** Inclusive start and exclusive end of the window, as ISO instants. */
  from: string;
  to: string;
  total: number;
  /** The same-length window immediately before this one. */
  previousTotal: number;
  byFortune: FortuneTally[];
  favourite: FortuneTally | null;
  /** Fortunes read in this window that the previous window never saw. */
  firstTime: FortuneTally[];
  /** When this reader tends to come, if there is a clear answer. */
  dayPart: DayPart | null;
  /** Distinct calendar days (app timezone) with at least one reading. */
  activeDays: number;
  /** The reading ids every number above was counted from. */
  sourceIds: string[];
}

const TITLES: ReadonlyMap<string, string> = new Map(
  FORTUNE_CATALOG.map((entry) => [entry.id, entry.titleFa] as const),
);

/** Catalog position — the tie-breaker, so equal counts still order stably. */
const CATALOG_ORDER: ReadonlyMap<string, number> = new Map(
  FORTUNE_CATALOG.map((entry, index) => [entry.id, index] as const),
);

function titleOf(fortuneId: string): string {
  return TITLES.get(fortuneId) ?? fortuneId;
}

function orderOf(fortuneId: string): number {
  return CATALOG_ORDER.get(fortuneId) ?? Number.MAX_SAFE_INTEGER;
}

/**
 * Local wall-clock fields for an instant, in the app timezone. The server
 * clock decides; the device clock is never consulted.
 */
function localParts(at: Date, timeZone: string): { dateKey: string; hour: number } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
  }).formatToParts(at);
  const get = (type: string): string => parts.find((p) => p.type === type)?.value ?? '';
  return {
    dateKey: `${get('year')}-${get('month')}-${get('day')}`,
    hour: Number(get('hour')),
  };
}

function dayPartOf(hour: number): DayPart {
  if (hour >= 5 && hour < 11) return 'morning';
  if (hour >= 11 && hour < 16) return 'noon';
  if (hour >= 16 && hour < 20) return 'evening';
  return 'night';
}

function tally(moments: readonly ReadingMoment[]): FortuneTally[] {
  const counts = new Map<string, number>();
  for (const moment of moments) {
    counts.set(moment.fortuneId, (counts.get(moment.fortuneId) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([fortuneId, count]) => ({ fortuneId, titleFa: titleOf(fortuneId), count }))
    .sort((a, b) => b.count - a.count || orderOf(a.fortuneId) - orderOf(b.fortuneId));
}

/**
 * Everything a history summary is allowed to know (scope §6).
 *
 * Pure and total: same readings and same instant in, same digest out. It
 * counts, it compares with the window before, and it stops there — no
 * judgement, no prediction, and nothing about anybody else.
 */
export function buildDigest(params: {
  moments: readonly ReadingMoment[];
  range: SummaryRange;
  now: Date;
  timeZone: string;
}): HistoryDigest {
  const { moments, range, now, timeZone } = params;
  const days = RANGE_DAYS[range];
  const dayMs = 24 * 60 * 60 * 1000;
  const to = now;
  const from = new Date(now.getTime() - days * dayMs);
  const previousFrom = new Date(from.getTime() - days * dayMs);

  const inWindow = moments.filter((m) => m.createdAt >= from && m.createdAt <= to);
  const inPrevious = moments.filter((m) => m.createdAt >= previousFrom && m.createdAt < from);

  const byFortune = tally(inWindow);
  const seenBefore = new Set(inPrevious.map((m) => m.fortuneId));

  const dayCounts = new Map<DayPart, number>();
  const activeDayKeys = new Set<string>();
  for (const moment of inWindow) {
    const { dateKey, hour } = localParts(moment.createdAt, timeZone);
    activeDayKeys.add(dateKey);
    const part = dayPartOf(hour);
    dayCounts.set(part, (dayCounts.get(part) ?? 0) + 1);
  }

  // A habit worth naming needs more than a single visit, and needs to be the
  // outright leader — a tie says nothing about when this person comes.
  let dayPart: DayPart | null = null;
  let best = 0;
  let tied = false;
  for (const part of DAY_PARTS) {
    const count = dayCounts.get(part) ?? 0;
    if (count > best) {
      best = count;
      dayPart = part;
      tied = false;
    } else if (count === best && count > 0) {
      tied = true;
    }
  }
  if (best < 2 || tied) dayPart = null;

  return {
    range,
    from: from.toISOString(),
    to: to.toISOString(),
    total: inWindow.length,
    previousTotal: inPrevious.length,
    byFortune,
    favourite: byFortune[0] ?? null,
    firstTime: byFortune.filter((entry) => !seenBefore.has(entry.fortuneId)),
    dayPart,
    activeDays: activeDayKeys.size,
    sourceIds: inWindow
      .slice()
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .map((m) => m.id),
  };
}

/**
 * A stable fingerprint of what the digest was built from. When a reading is
 * added — or deleted — this changes, so a cached summary about a reading that
 * no longer exists can never be served.
 */
export function digestFingerprint(digest: HistoryDigest): string {
  return `${digest.range}:${digest.total}:${digest.previousTotal}:${digest.sourceIds.join(',')}`;
}
