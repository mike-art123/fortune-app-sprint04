import { createHash } from 'node:crypto';

/**
 * Stable selection (docs/hafez-dataset-sourcing.md, step 3).
 *
 * The same intention on the same day draws the same ghazal — a fal that
 * changes when you refresh is not a fal. Selection is deliberately global
 * rather than per-user: the Divan is one book, and two people who bring the
 * same words to it on the same day open the same page. What differs between
 * them is the interpretation, which is where the person belongs.
 *
 * Everything here is pure. The hash is SHA-256 over
 * `edition\ndateKey\nnormalized-intention`, so a re-imported corpus (a new
 * edition tag) reshuffles openly, and yesterday's draw never leaks into
 * today's.
 */

const ARABIC_FOLDS: ReadonlyArray<[RegExp, string]> = [
  [/[يئ]/g, 'ی'],
  [/ك/g, 'ک'],
  [/ة/g, 'ه'],
  [/[أإآٱ]/g, 'ا'],
  [/ؤ/g, 'و'],
];

const DIGIT_SETS: ReadonlyArray<[RegExp, number]> = [
  [/[۰-۹]/g, 0x06f0],
  [/[٠-٩]/g, 0x0660],
];

/** Tashkeel, superscript alef and tatweel — decoration, not meaning. */
const DIACRITICS = /[ً-ْٰـ]/g;

/**
 * Folds an intention the way the client's search already folds Persian text:
 * Arabic letter variants onto Persian ones, digits onto ASCII, diacritics
 * dropped, whitespace collapsed. «سلامتي» and «سلامتی» are the same intention
 * and must draw the same ghazal.
 */
export function normalizeIntention(raw: string | undefined): string {
  let text = (raw ?? '').replace(DIACRITICS, '');
  for (const [pattern, replacement] of ARABIC_FOLDS) {
    text = text.replace(pattern, replacement);
  }
  for (const [pattern, base] of DIGIT_SETS) {
    text = text.replace(pattern, (digit) => String(digit.charCodeAt(0) - base));
  }
  return text.replace(/\s+/g, ' ').trim();
}

export interface GhazalDraw {
  edition: string;
  dateKey: string;
  intention: string;
  count: number;
}

/**
 * Draws a ghazal number in 1..count. The first 12 hex digits of the hash are
 * 48 bits — exact in a double, far past what 495 buckets can tell apart.
 */
export function selectGhazalNumber(draw: GhazalDraw): number {
  if (!Number.isInteger(draw.count) || draw.count <= 0) {
    throw new Error(`ghazal selection needs a positive count, got ${draw.count}`);
  }
  const digest = createHash('sha256')
    .update(`${draw.edition}\n${draw.dateKey}\n${normalizeIntention(draw.intention)}`, 'utf8')
    .digest('hex');
  const value = parseInt(digest.slice(0, 12), 16);
  return 1 + (value % draw.count);
}
