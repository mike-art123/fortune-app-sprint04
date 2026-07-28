import { computeTasbih, toPersianDigits } from './tasbih-count';

describe('computeTasbih', () => {
  it('is stable for the same intention on the same day', () => {
    const a = computeTasbih('2026-07-28', 'سلامتی');
    const b = computeTasbih('2026-07-28', 'سلامتی');
    expect(a).toEqual(b);
  });

  it('yields one of the three traditional outcomes and a plausible bead count', () => {
    for (let i = 0; i < 60; i++) {
      const { beads, result } = computeTasbih(`2026-07-${i}`, `نیت ${i}`);
      expect(['خوب', 'متوسط', 'صبر']).toContain(result);
      expect(beads).toBeGreaterThanOrEqual(7);
      expect(beads).toBeLessThanOrEqual(66);
    }
  });

  it('reads the outcome from the bead count', () => {
    const { beads, result } = computeTasbih('2026-07-28', 'کار');
    const remainder = beads % 3;
    const expected = remainder === 0 ? 'خوب' : remainder === 1 ? 'متوسط' : 'صبر';
    expect(result).toBe(expected);
  });

  it('folds Arabic and Persian spellings to the same outcome', () => {
    expect(computeTasbih('2026-07-28', 'سلامتي')).toEqual(computeTasbih('2026-07-28', 'سلامتی'));
  });
});

describe('toPersianDigits', () => {
  it('renders numbers in Persian digits', () => {
    expect(toPersianDigits(34)).toBe('۳۴');
    expect(toPersianDigits(0)).toBe('۰');
  });
});
