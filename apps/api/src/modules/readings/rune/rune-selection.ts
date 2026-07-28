import { createHash } from 'node:crypto';
import { normalizeIntention } from '../hafez/ghazal-selection';

/**
 * Stable single-rune draw for the rune fal.
 *
 * The same intention on the same day turns up the same rune — a fal that
 * changes when you refresh is not a fal. Selection is global rather than
 * per-user: two people who bring the same words on the same day draw the same
 * rune; what differs is the interpretation. Pure: SHA-256 over
 * `rune\ndateKey\nnormalized-intention`, the first 12 hex digits pick the
 * rune. We read upright, so there is no orientation to draw.
 */

export interface RuneDraw {
  dateKey: string;
  intention: string;
  deckSize: number;
}

export function drawRune(draw: RuneDraw): number {
  if (!Number.isInteger(draw.deckSize) || draw.deckSize <= 0) {
    throw new Error(`rune draw needs a positive deck size, got ${draw.deckSize}`);
  }
  const digest = createHash('sha256')
    .update(`rune\n${draw.dateKey}\n${normalizeIntention(draw.intention)}`, 'utf8')
    .digest('hex');
  return parseInt(digest.slice(0, 12), 16) % draw.deckSize;
}
