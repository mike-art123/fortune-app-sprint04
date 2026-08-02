import {
  abjadTitle,
  cardName,
  digits,
  forToday,
  hafezTitle,
  quranHumility,
  showsPersianSource,
  stripForToday,
  tarotTitle,
  tasbihTitle,
} from './reading-labels';

const ARABIC_SCRIPT = /[؀-ۿ]/;

/**
 * The eight raw engines frame the model's paragraphs with words of their own.
 * Those words were Persian in every language, which is how an English reading
 * came to wear the title «غزل ۲۱۹ دیوان حافظ».
 *
 * Two properties matter here and both are load-bearing: Persian must come out
 * exactly as it always did — it is every web and Play reader today, and every
 * existing provider spec calls these paths with no locale at all — and the
 * other three must contain no Persian at all, since half a translation reads
 * worse than none.
 */
describe('reading labels', () => {
  describe('Persian is the default and is unchanged', () => {
    it('answers in Persian when no locale is given', () => {
      expect(forToday()).toBe('برای امروز:');
      expect(hafezTitle(219)).toBe('غزل ۲۱۹ دیوان حافظ');
      expect(tarotTitle('دیوانه', true)).toBe('تاروت — دیوانه (وارونه)');
      expect(abjadTitle(digits(989))).toBe('فال ابجد — عددِ ۹۸۹');
      expect(tasbihTitle('خوب')).toBe('فال تسبیح — خوب');
    });

    it('answers in Persian for an unknown locale rather than guessing', () => {
      expect(forToday('de')).toBe('برای امروز:');
      expect(digits(7, 'de')).toBe('۷');
    });

    it('keeps Persian-only source text only for Persian readers', () => {
      expect(showsPersianSource()).toBe(true);
      expect(showsPersianSource('fa')).toBe(true);
      expect(showsPersianSource('en')).toBe(false);
      expect(showsPersianSource('tr')).toBe(false);
    });
  });

  describe('the other three carry no Persian', () => {
    for (const locale of ['en', 'tr']) {
      it(`${locale} labels are free of Arabic script`, () => {
        expect(forToday(locale)).not.toMatch(ARABIC_SCRIPT);
        expect(hafezTitle(219, locale)).not.toMatch(ARABIC_SCRIPT);
        expect(tarotTitle('The Fool', true, locale)).not.toMatch(ARABIC_SCRIPT);
        expect(tasbihTitle('خوب', locale)).not.toMatch(ARABIC_SCRIPT);
      });
    }

    it('writes ordinary digits outside Persian', () => {
      expect(digits(989, 'en')).toBe('989');
      expect(digits(989, 'ar')).toBe('989');
      expect(hafezTitle(219, 'en')).toBe('Ghazal 219 of the Divan of Hafez');
    });

    it('takes the card name the deck carries for that reader', () => {
      const card = { nameFa: 'دیوانه', nameEn: 'The Fool' };
      expect(cardName(card)).toBe('دیوانه');
      expect(cardName(card, 'fa')).toBe('دیوانه');
      expect(cardName(card, 'en')).toBe('The Fool');
      expect(cardName(card, 'tr')).toBe('The Fool');
    });

    it('still speaks Arabic where Arabic is the language, not the leftover', () => {
      expect(forToday('ar')).toBe('لهذا اليوم:');
      expect(quranHumility('ar')).not.toBe(quranHumility('fa'));
    });
  });

  describe('the closing phrase is stripped whichever language wrote it', () => {
    it.each([
      ['برای امروز: یک قدم کوچک بردار.', 'یک قدم کوچک بردار.'],
      ['For today: take one small step.', 'take one small step.'],
      ['لهذا اليوم: اخطُ خطوة صغيرة.', 'اخطُ خطوة صغيرة.'],
      ['Bugün için: küçük bir adım at.', 'küçük bir adım at.'],
    ])('strips %s', (given, expected) => {
      expect(stripForToday(given)).toBe(expected);
    });

    it('leaves a paragraph that never had the phrase alone', () => {
      expect(stripForToday('یک قدم کوچک بردار.')).toBe('یک قدم کوچک بردار.');
    });

    it('never doubles the phrase', () => {
      const advice = stripForToday('For today: rest a little.');
      expect(`${forToday('en')} ${advice}`).toBe('For today: rest a little.');
    });
  });
});
