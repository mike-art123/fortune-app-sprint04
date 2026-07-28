import { FORTUNE_CATALOG } from '../readings/fortune-catalog';

/**
 * Screens a search answer is allowed to point at. A closed list, written here
 * and nowhere else — a model can only ever pick from it.
 */
export const SEARCH_SCREENS = ['history', 'profile', 'fortunes'] as const;

export type SearchScreen = (typeof SEARCH_SCREENS)[number];

/**
 * What the server is willing to say back (scope §2 guardrail).
 *
 * Never a path, never free text: an id the catalog knows, or one of the
 * screens above, or nothing. The client resolves these into routes through its
 * own destination map, so a route still cannot be invented at either end.
 */
export type SearchInterpretation =
  | { kind: 'fortune'; fortuneId: string; titleFa: string }
  | { kind: 'screen'; screen: SearchScreen }
  | { kind: 'none' };

export const NO_INTERPRETATION: SearchInterpretation = { kind: 'none' };

function isScreen(value: string): value is SearchScreen {
  return (SEARCH_SCREENS as readonly string[]).includes(value);
}

/**
 * Validates whatever the model returned. Anything unrecognised — a made-up id,
 * a path, a sentence, the wrong shape — becomes "nothing", which cannot
 * navigate. This is the only door between the model and the app.
 */
export function interpretationFrom(object: Record<string, unknown>): SearchInterpretation {
  const kind = typeof object.kind === 'string' ? object.kind.trim() : '';

  if (kind === 'fortune') {
    const fortuneId = typeof object.fortuneId === 'string' ? object.fortuneId.trim() : '';
    const entry = FORTUNE_CATALOG.find((fortune) => fortune.id === fortuneId);
    return entry
      ? { kind: 'fortune', fortuneId: entry.id, titleFa: entry.titleFa }
      : NO_INTERPRETATION;
  }

  if (kind === 'screen') {
    const screen = typeof object.screen === 'string' ? object.screen.trim() : '';
    return isScreen(screen) ? { kind: 'screen', screen } : NO_INTERPRETATION;
  }

  return NO_INTERPRETATION;
}
