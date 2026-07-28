import { createHash } from 'node:crypto';
import { normalizeIntention } from '../hafez/ghazal-selection';

/**
 * Stable single-card draw for the tarot fal.
 *
 * The same intention on the same day turns up the same card in the same
 * orientation — a fal that changes when you refresh is not a fal. Selection is
 * global rather than per-user: two people who bring the same words on the same
 * day draw the same card; what differs is the interpretation. Everything here
 * is pure: SHA-256 over `tarot\ndateKey\nnormalized-intention`, the first 12
 * hex digits choose the card, the next two choose upright or reversed.
 */

export interface CardDraw {
  dateKey: string;
  intention: string;
  deckSize: number;
}

export interface DrawnCard {
  index: number;
  reversed: boolean;
}

export function drawCard(draw: CardDraw): DrawnCard {
  if (!Number.isInteger(draw.deckSize) || draw.deckSize <= 0) {
    throw new Error(`tarot draw needs a positive deck size, got ${draw.deckSize}`);
  }
  const digest = createHash('sha256')
    .update(`tarot\n${draw.dateKey}\n${normalizeIntention(draw.intention)}`, 'utf8')
    .digest('hex');
  const index = parseInt(digest.slice(0, 12), 16) % draw.deckSize;
  const reversed = parseInt(digest.slice(12, 14), 16) % 2 === 1;
  return { index, reversed };
}
