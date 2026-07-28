import { drawPlayingCard } from './cards-selection';

describe('drawPlayingCard', () => {
  it('is stable for the same intention on the same day', () => {
    const a = drawPlayingCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 52 });
    const b = drawPlayingCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 52 });
    expect(a).toBe(b);
  });

  it('always draws an index inside the deck', () => {
    for (let i = 0; i < 50; i++) {
      const index = drawPlayingCard({
        dateKey: `2026-07-${i}`,
        intention: `نیت ${i}`,
        deckSize: 52,
      });
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(52);
    }
  });

  it('folds Arabic and Persian spellings to the same draw', () => {
    const a = drawPlayingCard({ dateKey: '2026-07-28', intention: 'سلامتي', deckSize: 52 });
    const b = drawPlayingCard({ dateKey: '2026-07-28', intention: 'سلامتی', deckSize: 52 });
    expect(a).toBe(b);
  });

  it('rejects a non-positive deck size', () => {
    expect(() => drawPlayingCard({ dateKey: '2026-07-28', intention: 'x', deckSize: 0 })).toThrow(
      'positive deck size',
    );
  });
});
