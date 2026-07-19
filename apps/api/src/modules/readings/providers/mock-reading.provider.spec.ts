import { MockReadingProvider } from './mock-reading.provider';
import { FORTUNE_CATALOG } from '../fortune-catalog';

describe('MockReadingProvider', () => {
  const provider = new MockReadingProvider();

  it('returns structured non-empty Persian copy for every catalog entry', async () => {
    for (const fortune of FORTUNE_CATALOG) {
      const out = await provider.generate(fortune, {
        intention: 'نیت',
        narration: 'در باغی سبز راه می‌رفتم',
        selfName: 'سارا',
        otherName: 'امیر',
      });
      expect(out.title.length).toBeGreaterThan(0);
      expect(out.reading.length).toBeGreaterThan(20);
    }
  });

  it('weaves both names into the love reading', async () => {
    const love = FORTUNE_CATALOG.find((f) => f.id === 'love')!;
    const out = await provider.generate(love, { selfName: 'سارا', otherName: 'امیر' });
    expect(out.reading).toContain('سارا');
    expect(out.reading).toContain('امیر');
  });
});
