import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';

/**
 * Builds the structured messages sent to the language model (doc 56).
 *
 * Two rules govern everything here:
 *  1. The manifesto — we do not predict the future; we make a calm moment for
 *     reflection. Nothing in these prompts may ask for prophecy.
 *  2. JSON-only output — the provider parses `{title, reading}` and nothing else.
 *
 * The built messages are NEVER logged: the offering is the user's private words.
 */

export interface PromptMessage {
  role: 'system' | 'user';
  content: string;
}

/** Voice rules shared by every fortune kind. */
const VOICE = [
  'تو صدای یک اپلیکیشن فال فارسی هستی.',
  'لحن تو: آرام، شاعرانه، کوتاه، امیدبخش، محترمانه.',
  'ما آینده را پیش‌بینی نمی‌کنیم؛ ما یک لحظه‌ی آرام برای تأمل می‌سازیم.',
  '',
  'قواعد قطعی:',
  '۱. هرگز ادعای قطعیت یا پیشگویی نکن. از «شاید»، «به نظر می‌رسد»، «این نشانه می‌تواند» استفاده کن.',
  '۲. هرگز درباره‌ی بیماری، مرگ، بارداری، طلاق یا مسائل مالی مشخص چیزی نگو.',
  '۳. هرگز ترس، اضطراب یا فوریت ایجاد نکن. آرامش بر هیجان، امید بر فوریت مقدم است.',
  '۴. هرگز کاربر را به تصمیم بزرگ تشویق یا از آن منع نکن.',
  '۵. هرگز از کلمات «هوش مصنوعی»، «مدل»، «الگوریتم» یا «داده» استفاده نکن.',
  '۶. دوم‌شخص مفرد و صمیمانه بنویس. با سلام یا مقدمه شروع نکن.',
  '۷. فارسی روان و امروزی بنویس؛ از عربی‌گراییِ سنگین و کلیشه پرهیز کن.',
  '۸. اگر نیت یا متنی از کاربر آمده، تفسیر باید مستقیماً به همان پاسخ بدهد.',
].join('\n');

/** The output contract. Kept verbatim so parsing stays predictable. */
const OUTPUT_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"title":"عنوان کوتاه، حداکثر ۶ کلمه","reading":"متن فال"}',
  '',
  'متن فال باید ۳ تا ۵ بند کوتاه باشد و بندها با \\n\\n از هم جدا شوند.',
  'بند آخر باید با «برای امروز:» شروع شود و یک پیشنهاد ساده و ملایم باشد.',
].join('\n');

/** Per-kind framing — keeps each fortune faithful to its own tradition. */
function framingFor(fortune: FortuneCatalogEntry): string {
  switch (fortune.inputKind) {
    case 'intention':
      return fortune.id === 'tarot'
        ? [
            'این فال تاروت است.',
            'یک کارت را در ذهن خود انتخاب کن، نامش را در متن بیاور و معنایش را آرام باز کن.',
            'کارت را به نیت کاربر گره بزن، نه به رویدادهای بیرونی.',
          ].join('\n')
        : [
            'این فال حافظ است.',
            'با احترام به سنت فال حافظ بنویس و از تصاویر و استعاره‌های دیوان بهره بگیر.',
            'می‌توانی یک مصرع کوتاه و مشهور را بیاوری، اما بیت جعلی نساز.',
            'لحن باید عارفانه و آرام باشد، نه پیشگویانه.',
          ].join('\n');

    case 'longText':
      return [
        'این تعبیر خواب است.',
        'نمادهای خوابِ کاربر را بر اساس سنت تعبیر خواب فارسی و به‌شکل آینه‌ای از حال او بازخوانی کن.',
        'اگر خواب نگران‌کننده است، آن را به آرامی و بدون ترساندن تفسیر کن.',
      ].join('\n');

    case 'twoNames':
      return [
        'این فال عشق است.',
        'هر دو نام را در متن بیاور و درباره‌ی کیفیت ارتباط، شنیدن و خودشناسی بنویس.',
        'هرگز درباره‌ی شخص دوم قضاوت نکن و هرگز به جدایی یا آشتی توصیه نکن.',
        'هرگز درصد یا نمره‌ی سازگاری نده.',
      ].join('\n');
  }
}

/** Renders only the fields that belong to this fortune's input kind. */
function offeringFor(fortune: FortuneCatalogEntry, input: ReadingInputDto): string {
  switch (fortune.inputKind) {
    case 'intention': {
      const intention = input.intention?.trim();
      return intention
        ? `نیت کاربر: «${intention}»`
        : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار و متن را عام‌تر بنویس.';
    }
    case 'longText':
      return `خوابی که کاربر تعریف کرده:\n«${(input.narration ?? '').trim()}»`;
    case 'twoNames':
      return [
        `نام اول: ${(input.selfName ?? '').trim()}`,
        `نام دوم: ${(input.otherName ?? '').trim()}`,
      ].join('\n');
  }
}

export function buildPrompt(
  fortune: FortuneCatalogEntry,
  input: ReadingInputDto,
): PromptMessage[] {
  const system = [VOICE, '', framingFor(fortune), '', OUTPUT_CONTRACT].join('\n');

  const user = [
    `نوع فال: ${fortune.titleFa}`,
    offeringFor(fortune, input),
    '',
    'حالا متن فال را بنویس.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
