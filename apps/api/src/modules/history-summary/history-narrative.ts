import type { DayPart, HistoryDigest, SummaryRange } from './history-digest';

/**
 * The summary the app can always show (scope §6).
 *
 * This is not a fallback in the apologetic sense — it is the floor. Every
 * sentence below is a fact the reader could count themselves, phrased calmly
 * and in their own language. The model, when it is enabled and reachable, only
 * rewrites this more warmly; it never adds a fact that is not already here.
 */

const RANGE_FA: Record<SummaryRange, string> = {
  last7: 'هفت روز گذشته',
  last30: 'سی روز گذشته',
  last90: 'نود روز گذشته',
};

const DAY_PART_FA: Record<DayPart, string> = {
  morning: 'صبح‌ها',
  noon: 'ظهرها',
  evening: 'عصرها',
  night: 'شب‌ها',
};

const FA_DIGITS = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/** Numbers are read, not parsed — so they are shown the way they are read. */
function faNumber(value: number): string {
  return String(value).replace(/[0-9]/g, (d) => FA_DIGITS[Number(d)] ?? d);
}

export function rangeLabelFa(range: SummaryRange): string {
  return RANGE_FA[range];
}

/** The facts, as sentences. Never more than four, never a prediction. */
export function narrativeFrom(digest: HistoryDigest): string[] {
  const label = RANGE_FA[digest.range];
  if (digest.total === 0) {
    return [`در ${label} فالی نگرفته‌ای.`];
  }

  const lines: string[] = [];
  const count = faNumber(digest.total);
  const delta = digest.total - digest.previousTotal;

  if (digest.previousTotal === 0) {
    lines.push(`در ${label} ${count} فال گرفتی.`);
  } else if (delta > 0) {
    lines.push(`در ${label} ${count} فال گرفتی؛ ${faNumber(delta)} تا بیشتر از دورهٔ پیش.`);
  } else if (delta < 0) {
    lines.push(`در ${label} ${count} فال گرفتی؛ ${faNumber(-delta)} تا کمتر از دورهٔ پیش.`);
  } else {
    lines.push(`در ${label} ${count} فال گرفتی؛ درست به‌اندازهٔ دورهٔ پیش.`);
  }

  const favourite = digest.favourite;
  if (favourite !== null && favourite.count > 1) {
    lines.push(`بیشتر از همه سراغ ${favourite.titleFa} رفتی (${faNumber(favourite.count)} بار).`);
  }

  if (digest.dayPart !== null) {
    lines.push(`بیشترشان ${DAY_PART_FA[digest.dayPart]} بوده.`);
  }

  // "New" only means something when there was a previous period to be new to.
  if (digest.previousTotal > 0 && digest.firstTime.length > 0) {
    const names = digest.firstTime
      .slice(0, 3)
      .map((entry) => entry.titleFa)
      .join('، ');
    lines.push(`و ${names} را این دوره تازه آزمودی.`);
  }

  return lines;
}

/** The same facts as one paragraph — what the client shows when there is no
 * AI sentence to show instead. */
export function narrativeText(digest: HistoryDigest): string {
  return narrativeFrom(digest).join(' ');
}

/**
 * The counts handed to the model, as plain Persian. Nothing else is ever sent:
 * no reading text, no name, no birth month, no ids.
 */
export function digestFacts(digest: HistoryDigest): string[] {
  const facts = [
    `بازه: ${RANGE_FA[digest.range]}`,
    `تعداد فال‌ها: ${digest.total}`,
    `تعداد در دورهٔ پیش: ${digest.previousTotal}`,
    `روزهای فعال: ${digest.activeDays}`,
  ];
  for (const entry of digest.byFortune.slice(0, 5)) {
    facts.push(`${entry.titleFa}: ${entry.count}`);
  }
  if (digest.dayPart !== null) {
    facts.push(`بیشتر در: ${DAY_PART_FA[digest.dayPart]}`);
  }
  return facts;
}
