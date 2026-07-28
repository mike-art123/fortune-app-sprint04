import { drawLenormandCard } from './lenormand-selection';

describe('drawLenormandCard', () => {
  it('is stable for the same intention on the same day', () => {
    const a = drawLenormandCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 36 });
    const b = drawLenormandCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 36 });
    expect(a).toBe(b);
  });

  it('always draws an index inside the deck', () => {
    for (let i = 0; i < 50; i++) {
      const index = drawLenormandCard({
        dateKey: `2026-07-${i}`,
        intention: `نیت ${i}`,
        deckSize: 36,
      });
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(36);
    }
  });

  it('folds Arabic and Persian spellings to the same draw', () => {
    const a = drawLenormandCard({ dateKey: '2026-07-28', intention: 'سلامتي', deckSize: 36 });
    const b = drawLenormandCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 36 });
    expect(a).toBe(b);
  });

  it('rejects a non-positive deck size', () => {
    expect(() => drawLenormandCard({ dateKey: '2026-07-28', intention: 'x', deckSize: 0 })).toThrow(
      'positive deck size',
    );
  });
});
