import { createHash } from 'node:crypto';
import { normalizeIntention } from '../hafez/ghazal-selection';

/**
 * Stable single-card draw for the playing-card fal.
 *
 * The same intention on the same day turns up the same card — a fal that
 * changes when you refresh is not a fal. Selection is global rather than
 * per-user: two people who bring the same words on the same day draw the same
 * card; what differs is the interpretation. Pure: SHA-256 over
 * `cards\ndateKey\nnormalized-intention`, the first 12 hex digits pick the
 * card. Cartomancy is read upright, so there is no orientation to draw.
 */

export interface CardDraw {
  dateKey: string;
  intention: string;
  deckSize: number;
}

export function drawPlayingCard(draw: CardDraw): number {
  if (!Number.isInteger(draw.deckSize) || draw.deckSize <= 0) {
    throw new Error(`cards draw needs a positive deck size, got ${draw.deckSize}`);
  }
  const digest = createHash('sha256')
    .update(`cards\n${draw.dateKey}\n${normalizeIntention(draw.intention)}`, 'utf8')
    .digest('hex');
  return parseInt(digest.slice(0, 12), 16) % draw.deckSize;
}
