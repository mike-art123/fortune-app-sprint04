/**
 * Server-side fortune catalog — the backend-authoritative source of truth for
 * which fortunes exist and what offering each requires. The mobile registry
 * mirrors this for UI; economic/validation decisions happen HERE (doc 52 §4.3).
 */
export type FortuneInputKind = 'intention' | 'longText' | 'twoNames';

export interface FortuneCatalogEntry {
  id: string;
  inputKind: FortuneInputKind;
  titleFa: string;
  /** Minimum meaningful words for longText offerings. */
  minWords?: number;
}

export const FORTUNE_CATALOG: readonly FortuneCatalogEntry[] = [
  { id: 'hafez', inputKind: 'intention', titleFa: 'فال حافظ' },
  { id: 'tarot', inputKind: 'intention', titleFa: 'تاروت' },
  { id: 'dream', inputKind: 'longText', titleFa: 'تعبیر خواب', minWords: 3 },
  { id: 'love', inputKind: 'twoNames', titleFa: 'فال عشق' },
] as const;

export function findFortune(id: string): FortuneCatalogEntry | undefined {
  return FORTUNE_CATALOG.find((f) => f.id === id);
}
