import { computeAbjad, renderBreakdown, toPersianDigits } from './abjad-numerology';

describe('computeAbjad', () => {
  it('counts a name by the great abjad', () => {
    // حافظ: ح(8) + ا(1) + ف(80) + ظ(900) = 989
    const result = computeAbjad('حافظ');
    expect(result.total).toBe(989);
    expect(result.letters.map((l) => l.value)).toEqual([8, 1, 80, 900]);
  });

  it('gives the Persian-only letters their Arabic twin value', () => {
    expect(computeAbjad('پ').total).toBe(2);
    expect(computeAbjad('چ').total).toBe(3);
    expect(computeAbjad('ژ').total).toBe(7);
    expect(computeAbjad('گ').total).toBe(20);
  });

  it('counts Arabic and Persian spellings of a word the same', () => {
    expect(computeAbjad('كلك').total).toBe(computeAbjad('کلک').total);
    expect(computeAbjad('يا').total).toBe(computeAbjad('یا').total);
  });

  it('ignores diacritics', () => {
    expect(computeAbjad('بَ').total).toBe(2);
  });

  it('skips spaces, digits and punctuation', () => {
    expect(computeAbjad('اب ۱۲!').total).toBe(3);
  });

  it('returns zero when there is nothing to count', () => {
    expect(computeAbjad('').total).toBe(0);
    expect(computeAbjad('۱۲۳ !!!').letters).toHaveLength(0);
    expect(computeAbjad(undefined).total).toBe(0);
  });
});

describe('toPersianDigits', () => {
  it('renders numbers in Persian digits', () => {
    expect(toPersianDigits(989)).toBe('۹۸۹');
    expect(toPersianDigits(0)).toBe('۰');
  });
});

describe('renderBreakdown', () => {
  it('shows the per-letter working', () => {
    expect(renderBreakdown(computeAbjad('حافظ').letters)).toBe('ح(۸) + ا(۱) + ف(۸۰) + ظ(۹۰۰)');
  });
});
