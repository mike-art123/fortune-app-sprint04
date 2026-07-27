import { normalizeIntention, selectGhazalNumber } from './ghazal-selection';

describe('normalizeIntention', () => {
  it('folds Arabic letter variants onto Persian ones', () => {
    expect(normalizeIntention('سلامتي و كار')).toBe('سلامتی و کار');
  });

  it('drops diacritics and tatweel', () => {
    expect(normalizeIntention('عشـــق حقیقیْ')).toBe('عشق حقیقی');
  });

  it('maps Persian and Arabic-Indic digits to ASCII', () => {
    expect(normalizeIntention('سال ۱۴۰۵ و ٣ آرزو')).toBe('سال 1405 و 3 آرزو');
  });

  it('collapses whitespace and trims', () => {
    expect(normalizeIntention('  دلِ   آرام \n ')).toBe('دلِ آرام');
  });

  it('treats absence as the empty intention', () => {
    expect(normalizeIntention(undefined)).toBe('');
  });
});

describe('selectGhazalNumber', () => {
  const base = { edition: 'ganjoor-db-2017', dateKey: '2026-07-27', count: 495 };

  it('is deterministic for the same draw', () => {
    const first = selectGhazalNumber({ ...base, intention: 'سلامتی' });
    const second = selectGhazalNumber({ ...base, intention: 'سلامتی' });
    expect(first).toBe(second);
  });

  it('draws the same ghazal for spelling variants of one intention', () => {
    const persian = selectGhazalNumber({ ...base, intention: 'سلامتی' });
    const arabic = selectGhazalNumber({ ...base, intention: 'سلامتي' });
    expect(arabic).toBe(persian);
  });

  it('stays inside 1..count across many draws', () => {
    for (let day = 1; day <= 60; day += 1) {
      const dateKey = `2026-08-${String(day).padStart(2, '0')}`;
      const number = selectGhazalNumber({ ...base, dateKey, intention: 'نیت' });
      expect(number).toBeGreaterThanOrEqual(1);
      expect(number).toBeLessThanOrEqual(base.count);
    }
  });

  it('lets a new day draw a new ghazal', () => {
    const draws = new Set<number>();
    for (let day = 1; day <= 30; day += 1) {
      const dateKey = `2026-09-${String(day).padStart(2, '0')}`;
      draws.add(selectGhazalNumber({ ...base, dateKey, intention: 'نیت' }));
    }
    expect(draws.size).toBeGreaterThan(1);
  });

  it('lets a new edition reshuffle openly', () => {
    const oldEdition = selectGhazalNumber({ ...base, intention: 'نیت' });
    const draws = new Set<number>();
    for (let salt = 0; salt < 20; salt += 1) {
      draws.add(selectGhazalNumber({ ...base, edition: `future-${salt}`, intention: 'نیت' }));
    }
    draws.add(oldEdition);
    expect(draws.size).toBeGreaterThan(1);
  });

  it('draws for the silent intention too', () => {
    const number = selectGhazalNumber({ ...base, intention: '' });
    expect(number).toBeGreaterThanOrEqual(1);
    expect(number).toBeLessThanOrEqual(base.count);
  });

  it('refuses a count that cannot be drawn from', () => {
    expect(() => selectGhazalNumber({ ...base, intention: 'نیت', count: 0 })).toThrow();
  });
});
