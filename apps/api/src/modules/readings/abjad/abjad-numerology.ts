/**
 * Abjad numerals — حسابِ ابجدِ کبیر in the eastern (Mashriqi) order. Each
 * letter's value is fixed by a thousand-year-old convention, so this file is
 * the one place those values live: it lets the reading engine hand the model
 * a number it did not have to add up itself. Verified against the standard
 * table (Wikipedia, "Abjad numerals", Mashriqi order).
 *
 * Persian-only letters take their traditional Arabic twin's value —
 * پ→ب(2), چ→ج(3), ژ→ز(7), گ→ک(20).
 */

/** Arabic letter variants folded onto the Persian letters the table is keyed
 *  by, so «ك» and «ک», «ي» and «ی» count the same. Mirrors the fold the
 *  ghazal selection already uses. */
const ARABIC_FOLDS: ReadonlyArray<[RegExp, string]> = [
  [/[يئ]/g, 'ی'],
  [/ك/g, 'ک'],
  [/ة/g, 'ه'],
  [/[أإآٱ]/g, 'ا'],
  [/ؤ/g, 'و'],
];

/** Tashkeel, superscript alef and tatweel carry no numeric value. */
const DIACRITICS = /[ً-ْٰـ]/g;

/** Letter → abjad-kabir value, keyed by the folded Persian form. */
const ABJAD_KABIR = new Map<string, number>([
  ['ا', 1],
  ['ب', 2],
  ['پ', 2],
  ['ج', 3],
  ['چ', 3],
  ['د', 4],
  ['ه', 5],
  ['و', 6],
  ['ز', 7],
  ['ژ', 7],
  ['ح', 8],
  ['ط', 9],
  ['ی', 10],
  ['ک', 20],
  ['گ', 20],
  ['ل', 30],
  ['م', 40],
  ['ن', 50],
  ['س', 60],
  ['ع', 70],
  ['ف', 80],
  ['ص', 90],
  ['ق', 100],
  ['ر', 200],
  ['ش', 300],
  ['ت', 400],
  ['ث', 500],
  ['خ', 600],
  ['ذ', 700],
  ['ض', 800],
  ['ظ', 900],
  ['غ', 1000],
]);

const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';

/** Renders a Latin-digit number in Persian digits, the way the reading shows
 *  it to the user. */
export function toPersianDigits(value: number): string {
  return String(value)
    .split('')
    .map((digit) => PERSIAN_DIGITS[Number(digit)] ?? digit)
    .join('');
}

export interface AbjadLetter {
  letter: string;
  value: number;
}

export interface AbjadResult {
  /** Every counted letter, in order, with its value. */
  letters: AbjadLetter[];
  /** The sum — the number the whole reading is built on. */
  total: number;
}

/** Folds Arabic variants onto Persian letters and drops diacritics, so the
 *  same name spelled two ways counts to the same number. */
function fold(raw: string): string {
  let text = raw.replace(DIACRITICS, '');
  for (const [pattern, replacement] of ARABIC_FOLDS) {
    text = text.replace(pattern, replacement);
  }
  return text;
}

/**
 * Counts a name or intention by the great abjad. Anything outside the table —
 * spaces, digits, Latin, punctuation — carries no value and is skipped, so the
 * total is exactly the sum of the Arabic/Persian letters present. An input
 * with no such letters returns a total of zero, which the provider reads as
 * "nothing to count" and steps aside.
 */
export function computeAbjad(raw: string | undefined): AbjadResult {
  const text = fold(raw ?? '');
  const letters: AbjadLetter[] = [];
  let total = 0;
  for (const ch of text) {
    const value = ABJAD_KABIR.get(ch);
    if (value === undefined) continue;
    letters.push({ letter: ch, value });
    total += value;
  }
  return { letters, total };
}

/** Renders the per-letter sum the way the reading shows its working:
 *  «ح(۸) + ا(۱) + ف(۸۰) + ظ(۹۰۰)». */
export function renderBreakdown(letters: readonly AbjadLetter[]): string {
  return letters.map(({ letter, value }) => `${letter}(${toPersianDigits(value)})`).join(' + ');
}
