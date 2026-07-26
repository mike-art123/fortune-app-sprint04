import { MockReadingProvider } from './mock-reading.provider';
import { FORTUNE_CATALOG } from '../fortune-catalog';

describe('MockReadingProvider', () => {
  const provider = new MockReadingProvider();
  const love = FORTUNE_CATALOG.find((f) => f.id === 'love')!;

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
    const out = await provider.generate(love, { selfName: 'سارا', otherName: 'امیر' });
    expect(out.reading).toContain('سارا');
    expect(out.reading).toContain('امیر');
  });

  it('opens with the confirmed display name exactly once (scope §16)', async () => {
    const out = await provider.generate(
      love,
      { selfName: 'سارا', otherName: 'امیر' },
      { displayName: 'علی' },
    );
    expect(out.reading.startsWith('علی، ')).toBe(true);
    expect(out.reading.split('علی').length - 1).toBe(1);
  });

  it('stays impersonal when no confirmed name exists', async () => {
    const out = await provider.generate(love, { selfName: 'سارا', otherName: 'امیر' });
    expect(out.reading.startsWith('سارا و امیر')).toBe(true);
    expect(out.reading).toContain('سارا');
    expect(out.reading).toContain('امیر');
  });
});
