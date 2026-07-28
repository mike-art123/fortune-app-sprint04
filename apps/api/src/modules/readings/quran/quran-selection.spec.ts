import { drawVerse } from './quran-selection';

describe('drawVerse', () => {
  it('is stable for the same intention on the same day', () => {
    const a = drawVerse({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 27 });
    const b = drawVerse({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 27 });
    expect(a).toBe(b);
  });

  it('always draws an index inside the set', () => {
    for (let i = 0; i < 50; i++) {
      const index = drawVerse({
        dateKey: `2026-07-${i}`,
        intention: `نیت ${i}`,
        deckSize: 27,
      });
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(27);
    }
  });

  it('folds Arabic and Persian spellings to the same draw', () => {
    const a = drawVerse({ dateKey: '2026-07-28', intention: 'سلامتي', deckSize: 27 });
    const b = drawVerse({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 27 });
    expect(a).toBe(b);
  });

  it('rejects a non-positive verse count', () => {
    expect(() => drawVerse({ dateKey: '2026-07-28', intention: 'x', deckSize: 0 })).toThrow(
      'positive verse count',
    );
  });
});
