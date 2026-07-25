/**
 * Server-side fortune catalog — the backend-authoritative source of truth for
 * which fortunes exist and what offering each requires. The mobile registry
 * mirrors this for UI; economic/validation decisions happen HERE (doc 52 §4.3).
 *
 * `framingFa` is the per-fortune framing handed to the prompt builder so every
 * fortune stays faithful to its own tradition. `coffee` and `elements` are NOT
 * here on purpose — they are content guides in the app, not generated readings.
 */
export type FortuneInputKind = 'intention' | 'longText' | 'twoNames';

export interface FortuneCatalogEntry {
  id: string;
  inputKind: FortuneInputKind;
  titleFa: string;
  /** Per-fortune framing for the language model. */
  framingFa: string;
  /** Minimum meaningful words for longText offerings. */
  minWords?: number;
}

export const FORTUNE_CATALOG: readonly FortuneCatalogEntry[] = [
  {
    id: 'hafez',
    inputKind: 'intention',
    titleFa: 'فال حافظ',
    framingFa: 'فال حافظ است؛ عارفانه و با تصاویر دیوان بنویس، بیت جعلی نساز و پیشگویی نکن.',
  },
  {
    id: 'tarot',
    inputKind: 'intention',
    titleFa: 'تاروت',
    framingFa: 'فال تاروت است؛ یک کارت را نام ببر و معنایش را آرام به نیتِ کاربر گره بزن.',
  },
  {
    id: 'dream',
    inputKind: 'longText',
    titleFa: 'تعبیر خواب',
    minWords: 3,
    framingFa: 'تعبیر خواب است؛ نمادها را مثلِ آینه‌ی حالِ او و بی‌ترس بازخوانی کن.',
  },
  {
    id: 'love',
    inputKind: 'twoNames',
    titleFa: 'فال عشق',
    framingFa: 'فال عشق است؛ هر دو نام را بیاور، بی‌قضاوت بنویس و درصد یا نمره‌ی سازگاری نده.',
  },
  {
    id: 'abjad',
    inputKind: 'intention',
    titleFa: 'فال ابجد',
    framingFa: 'فال ابجد است؛ با حروف و اعداد، نیتِ کاربر را به نشانه‌ای امیدبخش پیوند بده.',
  },
  {
    id: 'marriage',
    inputKind: 'twoNames',
    titleFa: 'فال ازدواج',
    framingFa: 'فال ازدواج است؛ با هر دو نام از همراهی و تفاهم بگو، حکمِ زمان یا قطعیت نده.',
  },
  {
    id: 'child',
    inputKind: 'intention',
    titleFa: 'فال فرزند',
    framingFa: 'فال فرزند است؛ از مهر و صبر و امید بگو؛ درباره‌ی بارداری یا سلامت چیزی نگو.',
  },
  {
    id: 'friendship',
    inputKind: 'intention',
    titleFa: 'فال دوستی',
    framingFa: 'فال دوستی است؛ از اعتماد، صداقت و ارزشِ دوستیِ واقعی بنویس.',
  },
  {
    id: 'separation',
    inputKind: 'intention',
    titleFa: 'فال جدایی',
    framingFa: 'فال جدایی است؛ با ملایمت از پذیرش و مراقبت از خود بگو و اضطراب نساز.',
  },
  {
    id: 'reconcile',
    inputKind: 'twoNames',
    titleFa: 'فال آشتی',
    framingFa: 'فال آشتی است؛ با هر دو نام از گشودگی و بخشش بگو و بازگشت را قطعی نکن.',
  },
  {
    id: 'name',
    inputKind: 'intention',
    titleFa: 'فال اسم',
    framingFa: 'فال اسم است؛ از حس و آهنگِ نام، ویژگی‌های نیک و مسیرِ رشد را آرام بگو.',
  },
  {
    id: 'job',
    inputKind: 'intention',
    titleFa: 'فال شغل',
    framingFa: 'فال شغل است؛ از تلاش و صبر با امید بگو؛ درباره‌ی استخدام یا اخراج حکم نده.',
  },
  {
    id: 'money',
    inputKind: 'intention',
    titleFa: 'فال مالی',
    framingFa: 'فال مالی است؛ از قدرشناسی و میانه‌روی بگو و عدد یا توصیه‌ی مالی نده.',
  },
  {
    id: 'travel',
    inputKind: 'intention',
    titleFa: 'فال سفر',
    framingFa: 'فال سفر است؛ از گشودگی به راه‌های تازه بگو، بیرونی یا درونی، بی‌قطعیت.',
  },
  {
    id: 'future',
    inputKind: 'intention',
    titleFa: 'فال آینده',
    framingFa: 'فال آینده است؛ از امید و بذرهای امروز بگو و رویدادِ مشخص پیش‌بینی نکن.',
  },
  {
    id: 'message',
    inputKind: 'intention',
    titleFa: 'فال پیام',
    framingFa: 'فال پیام است؛ یک پیامِ کوتاهِ آرام و امیدبخش بیاور، بی‌ادعای قطعیت.',
  },
  {
    id: 'intention',
    inputKind: 'intention',
    titleFa: 'فال نیت',
    framingFa: 'فالِ نیت است؛ نیتِ قلبیِ کاربر را با احترام بازتاب بده، بی‌پیشگویی.',
  },
  {
    id: 'yesno',
    inputKind: 'intention',
    titleFa: 'بله یا خیر',
    framingFa: 'فالِ بله یا خیر است؛ به‌جای حکم، تمایلی آرام (بیشتر آری، بیشتر نه، یا صبر) بده.',
  },
  {
    id: 'luckynumber',
    inputKind: 'intention',
    titleFa: 'عدد شانس',
    framingFa: 'فالِ عددِ شانس است؛ یک عددِ کوچکِ خوش‌یمن برای امروز بده، سبک و بی‌قطعیت.',
  },
  {
    id: 'luckycolor',
    inputKind: 'intention',
    titleFa: 'رنگ شانس',
    framingFa: 'فالِ رنگِ شانس است؛ یک رنگِ آرام برای امروز پیشنهاد بده و حسش را بگو.',
  },
  {
    id: 'luckystone',
    inputKind: 'intention',
    titleFa: 'سنگ شانس',
    framingFa: 'فالِ سنگِ شانس است؛ یک سنگِ آرام‌بخش پیشنهاد بده، بی‌ادعای درمانی.',
  },
  {
    id: 'luckyflower',
    inputKind: 'intention',
    titleFa: 'گل شانس',
    framingFa: 'فالِ گلِ شانس است؛ یک گل انتخاب کن و پیامِ لطیفش را کوتاه بگو.',
  },
  {
    id: 'dailytalisman',
    inputKind: 'intention',
    titleFa: 'طلسم روزانه',
    framingFa: 'فالِ طلسمِ روزانه است؛ یک نمادِ محافظ و آرام‌بخش برای امروز بده، بی‌ترس.',
  },
  {
    id: 'lots',
    inputKind: 'intention',
    titleFa: 'فال قرعه',
    framingFa: 'فالِ قرعه است؛ مثلِ قرعه‌ی سنتی یک نشانه‌ی آرام برای نیت بده، بی‌قطعیت.',
  },
  {
    id: 'birthmonth',
    inputKind: 'intention',
    titleFa: 'ماه تولد',
    framingFa: 'فالِ ماهِ تولد است؛ از خوی و توانِ کلی بر پایه‌ی فصلِ تولد آرام بگو.',
  },
  {
    id: 'daily',
    inputKind: 'intention',
    titleFa: 'فال روزانه',
    framingFa: 'فالِ روزانه است؛ یک پیامِ کوتاهِ ویژه‌ی امروز بنویس، تازه و امیدبخش.',
  },
  {
    id: 'universe',
    inputKind: 'intention',
    titleFa: 'فال کائنات',
    framingFa: 'فالِ کائنات است؛ مثلِ پیامی از جهان، به اعتماد و گشودگی دعوت کن.',
  },
  {
    id: 'tea',
    inputKind: 'intention',
    titleFa: 'فال چای',
    framingFa: 'فالِ چای است؛ از نقش‌های خیالیِ برگ‌های چای تفسیری آرام بساز.',
  },
  {
    id: 'candle',
    inputKind: 'intention',
    titleFa: 'فال شمع',
    framingFa: 'فالِ شمع است؛ از نور و شعله و سایه تفسیری آرام و بی‌ترس بساز.',
  },
  {
    id: 'mirror',
    inputKind: 'intention',
    titleFa: 'فال آینه',
    framingFa: 'فالِ آینه است؛ آینه را نمادِ خودشناسی بگیر و به روشنیِ درون دعوت کن.',
  },
  {
    id: 'lenormand',
    inputKind: 'intention',
    titleFa: 'فال لنورمان',
    framingFa: 'فالِ لنورمان است؛ یک کارت را نام ببر و معنایش را آرام به نیت گره بزن.',
  },
  {
    id: 'rune',
    inputKind: 'intention',
    titleFa: 'فال رون',
    framingFa: 'فالِ رون است؛ یک نشانه‌ی رونیِ باستانی را با معنای نمادینش آرام بگو.',
  },
  {
    id: 'cards',
    inputKind: 'intention',
    titleFa: 'فال کارتی',
    framingFa: 'فالِ کارتی و اوراکل است؛ یک کارتِ الهام را با پیامِ مثبتش بیاور.',
  },
  {
    id: 'quran',
    inputKind: 'intention',
    titleFa: 'فال قرآن',
    framingFa: 'استخاره‌ی قرآن است؛ با احترامِ کامل و بی‌فتوا، فقط تلنگری برای تأمل بده.',
  },
  {
    id: 'tasbih',
    inputKind: 'intention',
    titleFa: 'فال تسبیح',
    framingFa: 'فالِ تسبیح است؛ مثلِ دانه‌های تسبیح یک نشانه‌ی آرام (بگیر، صبر، رها) بده.',
  },
  {
    id: 'angel',
    inputKind: 'intention',
    titleFa: 'پیام فرشتگان',
    framingFa: 'پیامِ فرشتگان است؛ یک پیامِ لطیف، مهربان و امیدبخش بیاور.',
  },
  {
    id: 'spiritanimal',
    inputKind: 'intention',
    titleFa: 'حیوان روح',
    framingFa: 'فالِ حیوانِ روح است؛ یک حیوانِ همراه انتخاب کن و خوی‌های نیکش را بازتاب بده.',
  },
  {
    id: 'meditation',
    inputKind: 'intention',
    titleFa: 'مدیتیشن',
    framingFa: 'فالِ مدیتیشن است؛ به یک لحظه‌ی سکوت، نفس و نیتِ روشن دعوت کن.',
  },
] as const;

export function findFortune(id: string): FortuneCatalogEntry | undefined {
  return FORTUNE_CATALOG.find((f) => f.id === id);
}
