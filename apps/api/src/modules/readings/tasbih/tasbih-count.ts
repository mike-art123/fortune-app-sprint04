import { createHash } from 'node:crypto';
import { normalizeIntention } from '../hafez/ghazal-selection';

/**
 * Tasbih istikhara (فال تسبیح), the deterministic seam.
 *
 * The person holds an intention and grabs a section of the prayer beads; the
 * count of those beads gives one of the three traditional outcomes — خوب
 * (good), متوسط (middling), صبر (wait). Here the grab is stable rather than
 * random: the same intention on the same day counts to the same beads and the
 * same outcome, because an istikhara you can re-roll until you like the answer
 * is not an istikhara. Pure: SHA-256 over `tasbih\ndateKey\nnormalized`; the
 * bead count is read from the digest, and the outcome follows from it.
 *
 * This is طلبِ خیر از خداوند in the traditional idiom, never a definitive
 * verdict — the framing and the reading keep that humility explicit.
 */

export type TasbihResult = 'خوب' | 'متوسط' | 'صبر';

export interface TasbihReading {
  /** The grabbed-bead count the outcome is read from. */
  beads: number;
  result: TasbihResult;
}

const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';

export function toPersianDigits(value: number): string {
  return String(value)
    .split('')
    .map((digit) => PERSIAN_DIGITS[Number(digit)] ?? digit)
    .join('');
}

export function computeTasbih(dateKey: string, intention: string): TasbihReading {
  const digest = createHash('sha256')
    .update(`tasbih\n${dateKey}\n${normalizeIntention(intention)}`, 'utf8')
    .digest('hex');
  const value = parseInt(digest.slice(0, 12), 16);
  const beads = 7 + (value % 60); // a plausible handful, 7..66
  const remainder = beads % 3;
  const result: TasbihResult = remainder === 0 ? 'خوب' : remainder === 1 ? 'متوسط' : 'صبر';
  return { beads, result };
}
