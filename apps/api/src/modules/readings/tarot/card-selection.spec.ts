import { drawCard } from './card-selection';

describe('drawCard', () => {
  it('is stable for the same intention on the same day', () => {
    const a = drawCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 78 });
    const b = drawCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 78 });
    expect(a).toEqual(b);
  });

  it('always draws an index inside the deck, with a boolean orientation', () => {
    for (let i = 0; i < 50; i++) {
      const { index, reversed } = drawCard({
        dateKey: `2026-07-${i}`,
        intention: `نیت ${i}`,
        deckSize: 78,
      });
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(78);
      expect(typeof reversed).toBe('boolean');
    }
  });

  it('folds Arabic and Persian spellings to the same draw', () => {
    const a = drawCard({ dateKey: '2026-07-28', intention: 'سلامتي', deckSize: 78 });
    const b = drawCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 78 });
    expect(a).toEqual(b);
  });

  it('rejects a non-positive deck size', () => {
    expect(() => drawCard({ dateKey: '2026-07-28', intention: 'x', deckSize: 0 })).toThrow(
      'positive deck size',
    );
  });
});
