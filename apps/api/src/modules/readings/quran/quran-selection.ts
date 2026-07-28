import { createHash } from 'node:crypto';
import { normalizeIntention } from '../hafez/ghazal-selection';

/**
 * Stable single-verse draw for the Quran tafa'ul (reflection).
 *
 * The same intention on the same day turns to the same verse — a reflection
 * you can re-roll until it pleases you is not a reflection. Pure: SHA-256 over
 * `quran\ndateKey\nnormalized-intention`, the first 12 hex digits pick the
 * verse. This is تفأل — a point of reflection — never an omen or a verdict.
 */

export interface VerseDraw {
  dateKey: string;
  intention: string;
  deckSize: number;
}

export function drawVerse(draw: VerseDraw): number {
  if (!Number.isInteger(draw.deckSize) || draw.deckSize <= 0) {
    throw new Error(`quran draw needs a positive verse count, got ${draw.deckSize}`);
  }
  const digest = createHash('sha256')
    .update(`quran\n${draw.dateKey}\n${normalizeIntention(draw.intention)}`, 'utf8')
    .digest('hex');
  return parseInt(digest.slice(0, 12), 16) % draw.deckSize;
}
