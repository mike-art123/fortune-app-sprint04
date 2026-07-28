import { drawRune } from './rune-selection';

describe('drawRune', () => {
  it('is stable for the same intention on the same day', () => {
    const a = drawRune({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 24 });
    const b = drawRune({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 24 });
    expect(a).toBe(b);
  });

  it('always draws an index inside the set', () => {
    for (let i = 0; i < 50; i++) {
      const index = drawRune({
        dateKey: `2026-07-${i}`,
        intention: `نیت ${i}`,
        deckSize: 24,
      });
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(24);
    }
  });

  it('folds Arabic and Persian spellings to the same draw', () => {
    const a = drawRune({ dateKey: '2026-07-28', intention: 'سلامتي', deckSize: 24 });
    const b = drawRune({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 24 });
    expect(a).toBe(b);
  });

  it('rejects a non-positive deck size', () => {
    expect(() => drawRune({ dateKey: '2026-07-28', intention: 'x', deckSize: 0 })).toThrow(
      'positive deck size',
    );
  });
});
