import { SUPPORTED_LOCALES, type SupportedLocale } from '../../../common/i18n/locale.util';

/**
 * The words the *server* adds to a reading, in the reader's own language.
 *
 * The eight raw engines do not hand the model a finished reading: they take
 * its paragraphs and frame them — a title, the card it drew, the traditional
 * meaning, and the closing "For today:". Every one of those was written in
 * Persian and stayed Persian no matter what language was asked for, so an
 * English reader got English paragraphs wearing a Persian title. The prompt
 * had even told the model to close with "For today:", and the code then
 * stripped that and pasted «برای امروز:» back over it.
 *
 * Persian is the default everywhere below. A provider called without a locale
 * — which is every existing test, and every request that predates phase E —
 * produces exactly the text it produced before.
 */

type Row = Record<SupportedLocale, string>;

function pick(row: Row, locale?: string): string {
  const known = (SUPPORTED_LOCALES as readonly string[]).includes(locale ?? '');
  return row[(known ? locale : 'fa') as SupportedLocale];
}

export function localeOf(locale?: string): SupportedLocale {
  return (SUPPORTED_LOCALES as readonly string[]).includes(locale ?? '')
    ? (locale as SupportedLocale)
    : 'fa';
}

/** Persian eyes read Persian digits; everyone else reads their own. */
const FA_DIGITS = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
export function digits(value: number | string, locale?: string): string {
  const text = String(value);
  if (localeOf(locale) !== 'fa') return text;
  return text.replace(/[0-9]/g, (d) => FA_DIGITS[Number(d)] ?? d);
}

const FOR_TODAY: Row = {
  fa: 'برای امروز:',
  en: 'For today:',
  ar: 'لهذا اليوم:',
  tr: 'Bugün için:',
};
export const forToday = (locale?: string): string => pick(FOR_TODAY, locale);

/**
 * The model was asked to open its last paragraph with the phrase for the
 * language it was writing in, so strip whichever one it used before the
 * caller prepends its own. Stripping only the Persian form is how a reading
 * in English ended up saying "For today: For today: …" one edit from here.
 */
export function stripForToday(text: string): string {
  const heads = Object.values(FOR_TODAY).join('|');
  return text.replace(new RegExp(`^(?:${heads})\\s*`), '');
}

const YOUR_CARD: Row = {
  fa: 'کارتِ تو:',
  en: 'Your card:',
  ar: 'بطاقتك:',
  tr: 'Kartın:',
};
export const yourCard = (locale?: string): string => pick(YOUR_CARD, locale);

const YOUR_RUNE: Row = {
  fa: 'رونِ تو:',
  en: 'Your rune:',
  ar: 'رونك:',
  tr: 'Rünün:',
};
export const yourRune = (locale?: string): string => pick(YOUR_RUNE, locale);

const TRADITIONAL_MEANING: Row = {
  fa: 'معنای سنتی:',
  en: 'Traditional meaning:',
  ar: 'المعنى التقليدي:',
  tr: 'Geleneksel anlamı:',
};
export const traditionalMeaning = (locale?: string): string => pick(TRADITIONAL_MEANING, locale);

const UPRIGHT: Row = { fa: 'راست', en: 'upright', ar: 'مستقيمة', tr: 'düz' };
const REVERSED: Row = { fa: 'وارونه', en: 'reversed', ar: 'مقلوبة', tr: 'ters' };
export const orientation = (reversed: boolean, locale?: string): string =>
  pick(reversed ? REVERSED : UPRIGHT, locale);

/** Title suffix for a reversed card, already spaced and bracketed. */
const REVERSED_TAG: Row = {
  fa: ' (وارونه)',
  en: ' (Reversed)',
  ar: ' (مقلوبة)',
  tr: ' (Ters)',
};
export const reversedTag = (reversed: boolean, locale?: string): string =>
  reversed ? pick(REVERSED_TAG, locale) : '';

/**
 * A card's name in the reader's language where the deck carries one. Arabic
 * and Turkish decks are not in the data, and inventing translations for
 * seventy-eight tarot cards is not something this function should do — the
 * English name is what those traditions are read under anyway.
 */
export function cardName(names: { nameFa: string; nameEn: string }, locale?: string): string {
  return localeOf(locale) === 'fa' ? names.nameFa : names.nameEn;
}

/**
 * True when a Persian-only piece of source data should be left out rather
 * than shown to someone who cannot read it — the traditional meanings and the
 * Persian Qur'an translation. The model was given them and its own paragraphs
 * carry the sense; printing them raw would be the half-translated page this
 * whole module exists to end.
 */
export const showsPersianSource = (locale?: string): boolean => localeOf(locale) === 'fa';

// ── per-engine titles ────────────────────────────────────────────────────

export function hafezTitle(number: number, locale?: string): string {
  const n = digits(number, locale);
  return pick(
    {
      fa: `غزل ${n} دیوان حافظ`,
      en: `Ghazal ${n} of the Divan of Hafez`,
      ar: `غزل ${n} من ديوان حافظ`,
      tr: `Hafız Divanı — ${n}. gazel`,
    },
    locale,
  );
}

export function tarotTitle(name: string, reversed: boolean, locale?: string): string {
  const tag = reversedTag(reversed, locale);
  return pick(
    {
      fa: `تاروت — ${name}${tag}`,
      en: `Tarot — ${name}${tag}`,
      ar: `التاروت — ${name}${tag}`,
      tr: `Tarot — ${name}${tag}`,
    },
    locale,
  );
}

export function abjadTitle(total: string, locale?: string): string {
  return pick(
    {
      fa: `فال ابجد — عددِ ${total}`,
      en: `Abjad — number ${total}`,
      ar: `فأل الأبجد — العدد ${total}`,
      tr: `Ebced — sayı ${total}`,
    },
    locale,
  );
}

export function abjadWorking(word: string, body: string, locale?: string): string {
  return pick(
    {
      fa: `حسابِ ابجدِ «${word}»: ${body}`,
      en: `The abjad reckoning of “${word}”: ${body}`,
      ar: `حساب الأبجد لـ«${word}»: ${body}`,
      tr: `“${word}” için ebced hesabı: ${body}`,
    },
    locale,
  );
}

export function cardsTitle(name: string, locale?: string): string {
  return pick(
    {
      fa: `کارت — ${name}`,
      en: `Card — ${name}`,
      ar: `بطاقة — ${name}`,
      tr: `Kart — ${name}`,
    },
    locale,
  );
}

export function lenormandTitle(name: string, locale?: string): string {
  return pick(
    {
      fa: `لنورماند — ${name}`,
      en: `Lenormand — ${name}`,
      ar: `لينورمان — ${name}`,
      tr: `Lenormand — ${name}`,
    },
    locale,
  );
}

export function runeTitle(name: string, locale?: string): string {
  return pick(
    {
      fa: `رون — ${name}`,
      en: `Rune — ${name}`,
      ar: `رونة — ${name}`,
      tr: `Rün — ${name}`,
    },
    locale,
  );
}

/** Surah names live in the data in one script only, so they travel as they are. */
export function quranTitle(surah: string, locale?: string): string {
  return pick(
    {
      fa: `تفأل به قرآن — سورهٔ ${surah}`,
      en: `Qur’an — Surah ${surah}`,
      ar: `تفاؤل بالقرآن — سورة ${surah}`,
      tr: `Kur’an — ${surah} suresi`,
    },
    locale,
  );
}

export function quranReference(surah: string, ayah: string, locale?: string): string {
  return pick(
    {
      fa: `سورهٔ ${surah}، آیهٔ ${ayah}`,
      en: `Surah ${surah}, verse ${ayah}`,
      ar: `سورة ${surah}، الآية ${ayah}`,
      tr: `${surah} suresi, ${ayah}. ayet`,
    },
    locale,
  );
}

export function quranTranslation(translator: string, text: string, locale?: string): string {
  return pick(
    {
      fa: `ترجمه (${translator}): ${text}`,
      en: `Persian translation (${translator}): ${text}`,
      ar: `الترجمة الفارسية (${translator}): ${text}`,
      tr: `Farsça çeviri (${translator}): ${text}`,
    },
    locale,
  );
}

const TASBIH_RESULT: Record<string, Row> = {
  خوب: { fa: 'خوب', en: 'good', ar: 'خير', tr: 'iyi' },
  متوسط: { fa: 'متوسط', en: 'middling', ar: 'متوسط', tr: 'orta' },
  صبر: { fa: 'صبر', en: 'patience', ar: 'صبر', tr: 'sabır' },
};
export function tasbihResult(result: string, locale?: string): string {
  const row = TASBIH_RESULT[result];
  return row ? pick(row, locale) : result;
}

export function tasbihTitle(result: string, locale?: string): string {
  const r = tasbihResult(result, locale);
  return pick(
    {
      fa: `فال تسبیح — ${r}`,
      en: `Tasbih — ${r}`,
      ar: `فأل التسبيح — ${r}`,
      tr: `Tesbih falı — ${r}`,
    },
    locale,
  );
}

export function tasbihCount(beads: string, result: string, locale?: string): string {
  const r = tasbihResult(result, locale);
  return pick(
    {
      fa: `شمارشِ دانه‌ها: ${beads} دانه — نتیجه: ${r}`,
      en: `Beads counted: ${beads} — result: ${r}`,
      ar: `عدد الحبات: ${beads} — النتيجة: ${r}`,
      tr: `Sayılan tane: ${beads} — sonuç: ${r}`,
    },
    locale,
  );
}

const QURAN_HUMILITY: Row = {
  fa: 'یادآوری: این یک تفأل و نکتهٔ تأمل است، نه حکم؛ استخارهٔ حقیقی با نماز و توکل بر خداست.',
  en: 'A reminder: this is a moment of reflection, not a verdict; a true istikhara is made in prayer and trust in God.',
  ar: 'تذكير: هذا تفاؤل ووقفة تأمل، لا حكم؛ والاستخارة الحقيقية بالصلاة والتوكل على الله.',
  tr: 'Bir hatırlatma: bu bir tefeül ve düşünme anıdır, hüküm değil; gerçek istihare namaz ve Allah’a tevekkülledir.',
};
export const quranHumility = (locale?: string): string => pick(QURAN_HUMILITY, locale);

const TASBIH_HUMILITY: Row = {
  fa: 'یادآوری: استخاره طلبِ خیر از خداوند است، نه حکمِ حتمی؛ تصمیمِ نهایی با تدبیر و مشورتِ توست.',
  en: 'A reminder: istikhara asks God for what is good; it is not a certainty. The decision stays yours, with thought and counsel.',
  ar: 'تذكير: الاستخارة طلب الخير من الله، لا حكم قاطع؛ والقرار النهائي لك بالتدبر والمشورة.',
  tr: 'Bir hatırlatma: istihare Allah’tan hayır dilemektir, kesin bir hüküm değil; son karar, düşünüp danışarak yine senindir.',
};
export const tasbihHumility = (locale?: string): string => pick(TASBIH_HUMILITY, locale);
