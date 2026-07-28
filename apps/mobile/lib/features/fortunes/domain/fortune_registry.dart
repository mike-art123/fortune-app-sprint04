import 'package:flutter/material.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../shared/models/localized_text.dart';
import 'fortune_definition.dart';

/// Source of truth for every fortune family (Sprint 01).
/// Adding a fortune here is the ONLY change needed for it to appear in
/// Explore and gain a working Ritual Entry.
abstract final class FortuneRegistry {
  static const RitualPace _pace = RitualPace(
    enter: Duration(milliseconds: 500),
    step: Duration(milliseconds: 150),
  );

  // Per-fortune jewel accents: the four category accents + a few extras, so
  // each fortune's moon glow and ritual aura reads distinctly.
  static const _gold = CategoryAccents.hafez;
  static const _turq = CategoryAccents.tarot;
  static const _blue = CategoryAccents.dream;
  static const _rose = CategoryAccents.love;
  static const _copper = CategoryAccents.coffee;
  static const _violet = Color(0xFFA78BFA);
  static const _emerald = Color(0xFF5FBF8F);
  static const _amber = Color(0xFFE6A23C);
  static const _teal = Color(0xFF4FB6B0);
  static const _magenta = Color(0xFFCB6FB0);
  static const _sky = Color(0xFF6FA8DC);
  static const _jade = Color(0xFF7FC8A9);

  /// Every fortune family: the four backend-live rituals + coffee (soon), then
  /// the remaining catalog fortunes activated with shared ritual copy — each
  /// gets its own faithful voice from the backend framing, not this screen.
  static final List<FortuneDefinition> all = [..._core, ..._extended];

  static const List<FortuneDefinition> _core = [
    FortuneDefinition(
      id: 'hafez',
      accent: CategoryAccents.hafez,
      inputKind: FortuneInputKind.intention,
      title: LocalizedText(fa: 'فال حافظ', en: 'Hafez'),
      subtitle: LocalizedText(
        fa: 'نیت کن و از دیوان بپرس',
        en: 'Hold an intention, ask the Divan',
      ),
      ritualLine: LocalizedText(
        fa: 'نیتت را در دل نگه دار.',
        en: 'Hold your intention in your heart.',
      ),
      placeholder: LocalizedText(
        fa: '…یا این‌جا با خودت بگو',
        en: '…or whisper it here',
      ),
      cta: LocalizedText(
        fa: 'فال حافظ را باز کن',
        en: 'Open the Hafez reading',
      ),
      pace: RitualPace(
        enter: Duration(milliseconds: 500),
        step: Duration(milliseconds: 140),
      ),
    ),
    FortuneDefinition(
      id: 'tarot',
      accent: CategoryAccents.tarot,
      inputKind: FortuneInputKind.intention,
      title: LocalizedText(fa: 'تاروت', en: 'Tarot'),
      subtitle: LocalizedText(
        fa: 'پرسشی که می‌خواهی روشن شود',
        en: 'A question seeking light',
      ),
      ritualLine: LocalizedText(
        fa: 'به پرسشی فکر کن که می‌خواهی روشن شود.',
        en: 'Think of the question you want illuminated.',
      ),
      placeholder: LocalizedText(fa: '…یا این‌جا بپرس', en: '…or ask it here'),
      cta: LocalizedText(fa: 'کارت‌ها را بکش', en: 'Draw the cards'),
      pace: RitualPace(
        enter: Duration(milliseconds: 600),
        step: Duration(milliseconds: 170),
      ),
    ),
    FortuneDefinition(
      id: 'dream',
      accent: CategoryAccents.dream,
      inputKind: FortuneInputKind.longText,
      title: LocalizedText(fa: 'تعبیر خواب', en: 'Dream'),
      subtitle: LocalizedText(
        fa: 'خوابت را آرام تعریف کن',
        en: 'Tell your dream, gently',
      ),
      ritualLine: LocalizedText(
        fa: 'خوابت را همان‌طور که به یادت مانده، آرام تعریف کن.',
        en: 'Tell your dream just as you remember it, gently.',
      ),
      placeholder: LocalizedText(
        fa: 'از هر جایی که یادت می‌آید شروع کن…',
        en: 'Start anywhere you remember…',
      ),
      cta: LocalizedText(fa: 'تعبیر خوابم را ببین', en: 'See my dream reading'),
      guide: LocalizedText(
        fa: 'برای شروع، چند کلمه از خوابت کافی است.',
        en: 'A few words of your dream are enough to begin.',
      ),
      privacy: LocalizedText(
        fa: 'خوابت نزدِ خودت می‌مانَد؛ فقط برای همین تعبیر به کار می‌رود.',
        en: 'Your dream stays yours; it is used only for this reading.',
      ),
      minWords: 3,
      maxLength: 2000,
      pace: RitualPace(
        enter: Duration(milliseconds: 660),
        step: Duration(milliseconds: 180),
      ),
    ),
    FortuneDefinition(
      id: 'love',
      accent: CategoryAccents.love,
      inputKind: FortuneInputKind.twoNames,
      title: LocalizedText(fa: 'فال عشق', en: 'Love'),
      subtitle: LocalizedText(
        fa: 'دو نام، یک پیوند',
        en: 'Two names, one bond',
      ),
      ritualLine: LocalizedText(
        fa: 'دو نام، یک پیوند.',
        en: 'Two names, one bond.',
      ),
      placeholder: LocalizedText(fa: 'نامِ تو', en: 'Your name'),
      placeholderSecond: LocalizedText(fa: 'نامِ او', en: 'Their name'),
      cta: LocalizedText(fa: 'سازگاری را ببین', en: 'See the harmony'),
      guide: LocalizedText(
        fa: 'برای دیدنِ سازگاری، هر دو نام را بنویس.',
        en: 'Write both names to see the harmony.',
      ),
      privacy: LocalizedText(
        fa: 'نام‌ها فقط برای همین فال استفاده می‌شوند.',
        en: 'The names are used only for this reading.',
      ),
      maxLength: 60,
      pace: RitualPace(
        enter: Duration(milliseconds: 460),
        step: Duration(milliseconds: 130),
      ),
    ),
    FortuneDefinition(
      id: 'coffee',
      accent: CategoryAccents.coffee,
      inputKind: FortuneInputKind.photo,
      title: LocalizedText(fa: 'فال قهوه', en: 'Coffee'),
      subtitle: LocalizedText(
        fa: 'رازهای تهِ فنجان',
        en: 'Secrets at the bottom of the cup',
      ),
      ritualLine: LocalizedText(
        fa: 'فنجانت را وارونه کن و یک عکس بگیر.',
        en: 'Turn your cup over and take a photo.',
      ),
      cta: LocalizedText(fa: 'فنجان را بخوان', en: 'Read the cup'),
      availability: FortuneAvailability.available,
      pace: RitualPace(
        enter: Duration(milliseconds: 500),
        step: Duration(milliseconds: 150),
      ),
    ),
  ];

  static final List<FortuneDefinition> _extended = [
    _intent(
      'abjad',
      'فال ابجد',
      'حروف و اعداد',
      _gold,
      'نامت و نیتت را در دل بیاور.',
      'Bring your name and intention to heart.',
      'حسابِ ابجد را بگشا',
      'Open the abjad reckoning',
    ),
    _twoNames(
      'marriage',
      'فال ازدواج',
      'آیندهٔ ازدواج',
      _rose,
      'دو نام را بیاور؛ پیوندشان را می‌خوانیم.',
      'Bring both names; we read their bond.',
      'آیندهٔ پیوند را ببین',
      'See the future of the bond',
    ),
    _intent(
      'child',
      'فال فرزند',
      'فرزند داری؟',
      _magenta,
      'دست بر دل بگذار و به فردای خانه فکر کن.',
      'Rest a hand on your heart; think of tomorrow.',
      'فال فرزند را باز کن',
      'Open the child reading',
    ),
    _intent(
      'friendship',
      'فال دوستی',
      'دوستانِ واقعی',
      _teal,
      'چهرهٔ دوستانت را از دل بگذران.',
      'Let your friends pass through your heart.',
      'حقیقتِ دوستی را ببین',
      'See the truth of friendship',
    ),
    _intent(
      'separation',
      'فال جدایی',
      'پایانِ رابطه؟',
      _blue,
      'آنچه را رها می‌کنی، آرام به یاد بیاور.',
      'Gently recall what you are letting go.',
      'مسیرِ جدایی را بخوان',
      'Read the parting path',
    ),
    _twoNames(
      'reconcile',
      'فال آشتی',
      'بازگشتِ او',
      _rose,
      'دو نام، یک دلِ چشم‌به‌راه.',
      'Two names, one waiting heart.',
      'راهِ آشتی را ببین',
      'See the way back',
    ),
    _intent(
      'name',
      'فال اسم',
      'رازِ نامت',
      _violet,
      'نامت را در دل صدا بزن.',
      'Call your name within.',
      'رازِ نامت را بگشا',
      'Unfold the secret of your name',
    ),
    _intent(
      'job',
      'فال شغل',
      'آیندهٔ کاری',
      _emerald,
      'به راهی که می‌روی فکر کن.',
      'Think of the road you walk.',
      'آیندهٔ کاری‌ات را ببین',
      'See your working future',
    ),
    _intent(
      'money',
      'فال مالی',
      'ثروت و پول',
      _amber,
      'به روزی و دارایی‌ات نیت کن.',
      'Set an intention for your provision.',
      'فال مالی را باز کن',
      'Open the wealth reading',
    ),
    _intent(
      'travel',
      'فال سفر',
      'سفر در راه؟',
      _sky,
      'مقصدی را که در سر داری تصور کن.',
      'Picture the destination on your mind.',
      'راهِ سفر را بخوان',
      'Read the road ahead',
    ),
    _intent(
      'future',
      'فال آینده',
      'در انتظارِ من',
      _violet,
      'چشم‌هایت را ببند و به فردا بنگر.',
      'Close your eyes and look to tomorrow.',
      'پردهٔ آینده را کنار بزن',
      'Draw back the veil',
    ),
    _intent(
      'message',
      'فال پیام',
      'پیامی در راه',
      _turq,
      'دلت منتظرِ کدام خبر است؟',
      'Which news is your heart waiting for?',
      'پیامت را بگیر',
      'Receive your message',
    ),
    _intent(
      'intention',
      'فال نیت',
      'نیتِ قلبی',
      _gold,
      'نیتت را خالص کن؛ همین کافی‌ست.',
      'Make the intention pure; that is enough.',
      'فال نیت را باز کن',
      'Open the intention reading',
    ),
    _intent(
      'yesno',
      'بله یا خیر',
      'پاسخِ سریع',
      _amber,
      'پرسشت را کوتاه و روشن در دل بگو.',
      'Ask it short and clear, within.',
      'بله یا خیر را ببین',
      'See yes or no',
      offering: FortuneOffering.chips,
      chips: const [
        LocalizedText(fa: 'آیا این‌طور می‌شود؟', en: 'Will it turn out so?'),
        LocalizedText(fa: 'آیا پیش بروم؟', en: 'Should I go ahead?'),
        LocalizedText(fa: 'آیا او همان است؟', en: 'Is this the one?'),
      ],
    ),
    _intent(
      'luckynumber',
      'عدد شانس',
      'عددِ خوش‌یمن',
      _teal,
      'به بختت اعتماد کن.',
      'Trust your luck.',
      'عددِ شانست را ببین',
      'See your lucky number',
      offering: FortuneOffering.chips,
      chips: const [
        LocalizedText(fa: 'برای امروز', en: 'For today'),
        LocalizedText(fa: 'برای این هفته', en: 'For this week'),
        LocalizedText(fa: 'برای این ماه', en: 'For this month'),
      ],
    ),
    _intent(
      'luckycolor',
      'رنگ شانس',
      'رنگِ امروز',
      _magenta,
      'امروزت را رنگی تصور کن.',
      'Imagine today in colour.',
      'رنگِ امروزت را ببین',
      'See the colour of today',
      offering: FortuneOffering.colors,
    ),
    _intent(
      'luckystone',
      'سنگ شانس',
      'سنگِ متولد',
      _violet,
      'به ماهِ تولدت فکر کن.',
      'Think of your birth month.',
      'سنگِ تو را پیدا کن',
      'Find your stone',
      offering: FortuneOffering.months,
    ),
    _intent(
      'luckyflower',
      'گل شانس',
      'گلِ تو',
      _rose,
      'عطری را که دوست داری به یاد آور.',
      'Recall a scent you love.',
      'گلِ تو را ببین',
      'See your flower',
    ),
    _intent(
      'dailytalisman',
      'طلسم روزانه',
      'حفاظت و انرژی',
      _amber,
      'نیتِ محافظت کن.',
      'Set an intention of protection.',
      'طلسمِ امروز را بگیر',
      'Take the talisman of today',
    ),
    _intent(
      'lots',
      'فال قرعه',
      'قرعه و شانس',
      _copper,
      'نیت کن؛ قرعه به نامِ که می‌افتد؟',
      'Set your intention; whose lot will it be?',
      'قرعه را بینداز',
      'Cast the lot',
    ),
    _intent(
      'birthmonth',
      'ماه تولد',
      'طالع و شخصیت',
      _violet,
      'ماهِ تولدت را در دل بگو.',
      'Say your birth month within.',
      'طالعِ ماهت را ببین',
      'See the sign of your month',
      offering: FortuneOffering.months,
    ),
    _intent(
      'daily',
      'فال روزانه',
      'ویژهٔ امروز',
      _gold,
      'امروزت را به بخت بسپار.',
      'Entrust today to fortune.',
      'فالِ امروز را باز کن',
      'Open the daily reading',
    ),
    _intent(
      'universe',
      'فال کائنات',
      'پیامِ جهان',
      _violet,
      'پیامت را به کائنات بسپار.',
      'Entrust your message to the universe.',
      'پاسخِ کائنات را بشنو',
      'Hear the universe answer',
    ),
    _intent(
      'tea',
      'فال چای',
      'برگ‌های چای',
      _jade,
      'فنجانِ چای را در خیال گرم بگیر.',
      'Hold a warm cup in your mind.',
      'برگ‌های چای را بخوان',
      'Read the tea leaves',
    ),
    _intent(
      'candle',
      'فال شمع',
      'نور و انرژی',
      _amber,
      'شمعی در دلت روشن کن.',
      'Light a candle within.',
      'رقصِ شعله را بخوان',
      'Read the dancing flame',
    ),
    _intent(
      'mirror',
      'فال آینه',
      'آینهٔ آینده',
      _sky,
      'در آینهٔ دل به خودت نگاه کن.',
      'Look at yourself in the heart-mirror.',
      'رازِ آینه را ببین',
      'See the mirror secret',
    ),
    _intent(
      'lenormand',
      'فال لنورمان',
      'کارت‌های لنورمان',
      _turq,
      'پرسشت را به کارت‌ها بسپار.',
      'Give your question to the cards.',
      'کارت‌های لنورمان را بچین',
      'Lay the Lenormand cards',
    ),
    _intent(
      'rune',
      'فال رون',
      'حروفِ باستان',
      _copper,
      'به حروفِ کهن نیت کن.',
      'Set your intention on the old letters.',
      'رون‌ها را بینداز',
      'Cast the runes',
    ),
    _intent(
      'cards',
      'فال کارتی',
      'کارت‌های اوراکل',
      _teal,
      'کارتی را در دل انتخاب کن.',
      'Choose a card within.',
      'کارتت را برگردان',
      'Turn your card',
    ),
    _intent(
      'quran',
      'فال قرآن',
      'استخارهٔ قرآن',
      _emerald,
      'با دلی آرام استخاره کن.',
      'Seek guidance with a quiet heart.',
      'استخاره را بگشا',
      'Open the istikhara',
    ),
    _intent(
      'tasbih',
      'فال تسبیح',
      'دانه‌های تسبیح',
      _jade,
      'دانه‌ها را در دل بشمار و نیت کن.',
      'Count the beads within and intend.',
      'تسبیح را بگردان',
      'Turn the prayer beads',
    ),
    _intent(
      'angel',
      'پیام فرشتگان',
      'پیامِ فرشته',
      _sky,
      'چشم‌هایت را ببند؛ فرشته‌ات نزدیک است.',
      'Close your eyes; your angel is near.',
      'پیامِ فرشته را بگیر',
      'Receive the angel message',
    ),
    _intent(
      'spiritanimal',
      'حیوان روح',
      'حیوانِ روحِ تو',
      _copper,
      'به جانِ وحشیِ درونت گوش بده.',
      'Listen to the wild soul within.',
      'حیوانِ روحت را بیاب',
      'Find your spirit animal',
    ),
    _intent(
      'meditation',
      'مدیتیشن',
      'نیت‌گذاری',
      _teal,
      'سه نفسِ عمیق؛ سپس نیت کن.',
      'Three deep breaths; then intend.',
      'نیت‌گذاری را آغاز کن',
      'Begin the intention',
    ),
  ];

  /// Intention fortune with its own ritual voice: each fortune whispers its
  /// own line and names its own act — never a shared template sentence.
  static FortuneDefinition _intent(
    String id,
    String fa,
    String sub,
    Color a,
    String ritualFa,
    String ritualEn,
    String ctaFa,
    String ctaEn, {
    FortuneOffering offering = FortuneOffering.none,
    List<LocalizedText> chips = const [],
  }) {
    return FortuneDefinition(
      id: id,
      accent: a,
      inputKind: FortuneInputKind.intention,
      title: LocalizedText(fa: fa, en: fa),
      subtitle: LocalizedText(fa: sub, en: sub),
      ritualLine: LocalizedText(fa: ritualFa, en: ritualEn),
      placeholder: const LocalizedText(
        fa: '…یا این‌جا با خودت بگو',
        en: '…or whisper it here',
      ),
      cta: LocalizedText(fa: ctaFa, en: ctaEn),
      pace: _pace,
      offering: offering,
      offeringChips: chips,
    );
  }

  static FortuneDefinition _twoNames(
    String id,
    String fa,
    String sub,
    Color a,
    String ritualFa,
    String ritualEn,
    String ctaFa,
    String ctaEn,
  ) {
    return FortuneDefinition(
      id: id,
      accent: a,
      inputKind: FortuneInputKind.twoNames,
      title: LocalizedText(fa: fa, en: fa),
      subtitle: LocalizedText(fa: sub, en: sub),
      ritualLine: LocalizedText(fa: ritualFa, en: ritualEn),
      placeholder: const LocalizedText(fa: 'نامِ نخست', en: 'First name'),
      placeholderSecond: const LocalizedText(fa: 'نامِ دوم', en: 'Second name'),
      cta: LocalizedText(fa: ctaFa, en: ctaEn),
      guide: const LocalizedText(
        fa: 'برای این فال، هر دو نام را بنویس.',
        en: 'Write both names for this reading.',
      ),
      maxLength: 60,
      pace: _pace,
    );
  }

  static FortuneDefinition? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
