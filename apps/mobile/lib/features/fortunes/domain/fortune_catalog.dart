import '../../../shared/models/localized_text.dart';

/// Browse catalog for the «همه فال‌ها» grid.
///
/// A single entry: (id, title, subtitle, isLive). `id` matches
/// assets/fortunes/<id>.jpg and, when live, a FortuneRegistry id. Titles and
/// subtitles are locale-aware; the Persian voice is unchanged. A fortune that
/// is not live is shown as «به‌زودی» with a disabled action — never as a dead
/// card.
typedef FortuneItem = (String, LocalizedText, LocalizedText, bool);

/// A titled section of the catalog.
class FortuneGroup {
  const FortuneGroup(this.title, this.items);

  final LocalizedText title;
  final List<FortuneItem> items;
}

/// The full 40-fortune catalog, grouped by theme.
abstract final class FortuneCatalog {
  static const groups = <FortuneGroup>[
    FortuneGroup(
      LocalizedText(
        fa: 'فال‌های محبوب',
        en: 'Popular fortunes',
        ar: 'الفؤول الرائجة',
        tr: 'Sevilen fallar',
      ),
      [
        (
          'hafez',
          LocalizedText(
            fa: 'فال حافظ',
            en: 'Hafez',
            ar: 'فأل حافظ',
            tr: 'Hafız Falı',
          ),
          LocalizedText(
            fa: 'با غزل حافظ',
            en: 'With Hafez ghazals',
            ar: 'بغزليات حافظ',
            tr: 'Hafız gazelleriyle',
          ),
          true,
        ),
        (
          'coffee',
          LocalizedText(
            fa: 'فال قهوه',
            en: 'Coffee',
            ar: 'قراءة الفنجان',
            tr: 'Kahve Falı',
          ),
          LocalizedText(
            fa: 'با تفسیر کامل',
            en: 'With a full reading',
            ar: 'بتفسير كامل',
            tr: 'Tam yorumuyla',
          ),
          false,
        ),
        (
          'tarot',
          LocalizedText(
            fa: 'تاروت',
            en: 'Tarot',
            ar: 'التاروت',
            tr: 'Tarot',
          ),
          LocalizedText(
            fa: 'کارت‌های تاروت',
            en: 'The tarot cards',
            ar: 'بطاقات التاروت',
            tr: 'Tarot kartları',
          ),
          true,
        ),
        (
          'dream',
          LocalizedText(
            fa: 'تعبیر خواب',
            en: 'Dream',
            ar: 'تفسير الأحلام',
            tr: 'Rüya Tabiri',
          ),
          LocalizedText(
            fa: 'معنی رویاها',
            en: 'The meaning of dreams',
            ar: 'معاني الأحلام',
            tr: 'Rüyaların anlamı',
          ),
          true,
        ),
        (
          'love',
          LocalizedText(
            fa: 'فال عشق',
            en: 'Love',
            ar: 'فأل الحب',
            tr: 'Aşk Falı',
          ),
          LocalizedText(
            fa: 'روابط عاطفی',
            en: 'Matters of the heart',
            ar: 'علاقات القلب',
            tr: 'Kalp meseleleri',
          ),
          true,
        ),
        (
          'abjad',
          LocalizedText(
            fa: 'فال ابجد',
            en: 'Abjad',
            ar: 'فأل الأبجد',
            tr: 'Ebced Falı',
          ),
          LocalizedText(
            fa: 'حروف و اعداد',
            en: 'Letters and numbers',
            ar: 'حروف وأرقام',
            tr: 'Harfler ve sayılar',
          ),
          true,
        ),
      ],
    ),
    FortuneGroup(
      LocalizedText(
        fa: 'عشق و روابط',
        en: 'Love and relationships',
        ar: 'الحب والعلاقات',
        tr: 'Aşk ve ilişkiler',
      ),
      [
        (
          'marriage',
          LocalizedText(
            fa: 'فال ازدواج',
            en: 'Marriage',
            ar: 'فأل الزواج',
            tr: 'Evlilik Falı',
          ),
          LocalizedText(
            fa: 'آیندهٔ ازدواج',
            en: 'The future of a union',
            ar: 'مستقبل الزواج',
            tr: 'Evliliğin geleceği',
          ),
          true,
        ),
        (
          'child',
          LocalizedText(
            fa: 'فال فرزند',
            en: 'Child',
            ar: 'فأل الذرّية',
            tr: 'Çocuk Falı',
          ),
          LocalizedText(
            fa: 'فرزند داری؟',
            en: 'A child ahead?',
            ar: 'هل من ذرّية؟',
            tr: 'Çocuk var mı?',
          ),
          true,
        ),
        (
          'friendship',
          LocalizedText(
            fa: 'فال دوستی',
            en: 'Friendship',
            ar: 'فأل الصداقة',
            tr: 'Dostluk Falı',
          ),
          LocalizedText(
            fa: 'دوستانِ واقعی',
            en: 'True friends',
            ar: 'الأصدقاء الحقيقيون',
            tr: 'Gerçek dostlar',
          ),
          true,
        ),
        (
          'separation',
          LocalizedText(
            fa: 'فال جدایی',
            en: 'Parting',
            ar: 'فأل الفراق',
            tr: 'Ayrılık Falı',
          ),
          LocalizedText(
            fa: 'پایانِ رابطه؟',
            en: 'An ending near?',
            ar: 'نهاية العلاقة؟',
            tr: 'İlişkinin sonu mu?',
          ),
          true,
        ),
        (
          'reconcile',
          LocalizedText(
            fa: 'فال آشتی',
            en: 'Reunion',
            ar: 'فأل الصلح',
            tr: 'Barışma Falı',
          ),
          LocalizedText(
            fa: 'بازگشتِ او',
            en: 'Their return',
            ar: 'عودته إليك',
            tr: 'Onun dönüşü',
          ),
          true,
        ),
        (
          'name',
          LocalizedText(
            fa: 'فال اسم',
            en: 'Name',
            ar: 'فأل الاسم',
            tr: 'İsim Falı',
          ),
          LocalizedText(
            fa: 'رازِ نامت',
            en: 'The secret of your name',
            ar: 'سرّ اسمك',
            tr: 'Adının sırrı',
          ),
          true,
        ),
      ],
    ),
    FortuneGroup(
      LocalizedText(
        fa: 'کار و آینده',
        en: 'Work and future',
        ar: 'العمل والمستقبل',
        tr: 'İş ve gelecek',
      ),
      [
        (
          'job',
          LocalizedText(
            fa: 'فال شغل',
            en: 'Career',
            ar: 'فأل العمل',
            tr: 'İş Falı',
          ),
          LocalizedText(
            fa: 'آیندهٔ کاری',
            en: 'Your working future',
            ar: 'مستقبلك المهني',
            tr: 'Kariyerinin geleceği',
          ),
          true,
        ),
        (
          'money',
          LocalizedText(
            fa: 'فال مالی',
            en: 'Wealth',
            ar: 'فأل الرزق',
            tr: 'Bolluk Falı',
          ),
          LocalizedText(
            fa: 'ثروت و پول',
            en: 'Wealth and money',
            ar: 'المال والثروة',
            tr: 'Bolluk ve para',
          ),
          true,
        ),
        (
          'travel',
          LocalizedText(
            fa: 'فال سفر',
            en: 'Journey',
            ar: 'فأل السفر',
            tr: 'Yolculuk Falı',
          ),
          LocalizedText(
            fa: 'سفر در راه؟',
            en: 'A journey ahead?',
            ar: 'سفر في الطريق؟',
            tr: 'Yolda bir yolculuk mu?',
          ),
          true,
        ),
        (
          'future',
          LocalizedText(
            fa: 'فال آینده',
            en: 'Future',
            ar: 'فأل المستقبل',
            tr: 'Gelecek Falı',
          ),
          LocalizedText(
            fa: 'در انتظارِ من',
            en: 'Waiting for me',
            ar: 'ما ينتظرني',
            tr: 'Beni ne bekliyor',
          ),
          true,
        ),
        (
          'message',
          LocalizedText(
            fa: 'فال پیام',
            en: 'Message',
            ar: 'فأل الرسالة',
            tr: 'Mesaj Falı',
          ),
          LocalizedText(
            fa: 'پیامی در راه',
            en: 'A message coming',
            ar: 'رسالة في الطريق',
            tr: 'Yolda bir mesaj',
          ),
          true,
        ),
        (
          'intention',
          LocalizedText(
            fa: 'فال نیت',
            en: 'Intention',
            ar: 'فأل النيّة',
            tr: 'Niyet Falı',
          ),
          LocalizedText(
            fa: 'نیتِ قلبی',
            en: 'The heart\'s intent',
            ar: 'نيّة القلب',
            tr: 'Kalbin niyeti',
          ),
          true,
        ),
      ],
    ),
    FortuneGroup(
      LocalizedText(
        fa: 'شانس و انرژی',
        en: 'Luck and energy',
        ar: 'الحظ والطاقة',
        tr: 'Şans ve enerji',
      ),
      [
        (
          'yesno',
          LocalizedText(
            fa: 'بله یا خیر',
            en: 'Yes or No',
            ar: 'نعم أم لا',
            tr: 'Evet ya da Hayır',
          ),
          LocalizedText(
            fa: 'پاسخِ سریع',
            en: 'A quick answer',
            ar: 'جواب سريع',
            tr: 'Hızlı bir cevap',
          ),
          true,
        ),
        (
          'luckynumber',
          LocalizedText(
            fa: 'عدد شانس',
            en: 'Lucky Number',
            ar: 'رقم الحظ',
            tr: 'Şans Sayısı',
          ),
          LocalizedText(
            fa: 'عددِ خوش‌یمن',
            en: 'Your auspicious number',
            ar: 'رقمك الميمون',
            tr: 'Uğurlu sayın',
          ),
          true,
        ),
        (
          'luckycolor',
          LocalizedText(
            fa: 'رنگ شانس',
            en: 'Lucky Colour',
            ar: 'لون الحظ',
            tr: 'Şans Rengi',
          ),
          LocalizedText(
            fa: 'رنگِ امروز',
            en: 'Colour of today',
            ar: 'لون اليوم',
            tr: 'Bugünün rengi',
          ),
          true,
        ),
        (
          'luckystone',
          LocalizedText(
            fa: 'سنگ شانس',
            en: 'Birthstone',
            ar: 'حجر الحظ',
            tr: 'Şans Taşı',
          ),
          LocalizedText(
            fa: 'سنگِ متولد',
            en: 'Stone of your month',
            ar: 'حجر مولدك',
            tr: 'Doğduğun ayın taşı',
          ),
          true,
        ),
        (
          'luckyflower',
          LocalizedText(
            fa: 'گل شانس',
            en: 'Lucky Flower',
            ar: 'زهرة الحظ',
            tr: 'Şans Çiçeği',
          ),
          LocalizedText(
            fa: 'گلِ تو',
            en: 'Your flower',
            ar: 'زهرتك',
            tr: 'Senin çiçeğin',
          ),
          true,
        ),
        (
          'dailytalisman',
          LocalizedText(
            fa: 'طلسم روزانه',
            en: 'Daily Talisman',
            ar: 'طلسم اليوم',
            tr: 'Günün Tılsımı',
          ),
          LocalizedText(
            fa: 'حفاظت و انرژی',
            en: 'Protection and energy',
            ar: 'حماية وطاقة',
            tr: 'Koruma ve enerji',
          ),
          true,
        ),
        (
          'lots',
          LocalizedText(
            fa: 'فال قرعه',
            en: 'Lots',
            ar: 'فأل القرعة',
            tr: 'Kura Falı',
          ),
          LocalizedText(
            fa: 'قرعه و شانس',
            en: 'Lots and luck',
            ar: 'قرعة وحظّ',
            tr: 'Kura ve şans',
          ),
          true,
        ),
      ],
    ),
    FortuneGroup(
      LocalizedText(
        fa: 'آسترولوژی',
        en: 'Astrology',
        ar: 'التنجيم',
        tr: 'Astroloji',
      ),
      [
        (
          'birthmonth',
          LocalizedText(
            fa: 'ماه تولد',
            en: 'Birth Month',
            ar: 'شهر الميلاد',
            tr: 'Doğum Ayı',
          ),
          LocalizedText(
            fa: 'طالع و شخصیت',
            en: 'Sign and character',
            ar: 'الطالع والشخصية',
            tr: 'Yıldızın ve karakterin',
          ),
          true,
        ),
        (
          'daily',
          LocalizedText(
            fa: 'فال روزانه',
            en: 'Daily',
            ar: 'فأل اليوم',
            tr: 'Günlük Fal',
          ),
          LocalizedText(
            fa: 'ویژهٔ امروز',
            en: 'Made for today',
            ar: 'خاص بهذا اليوم',
            tr: 'Bugüne özel',
          ),
          true,
        ),
        (
          'elements',
          LocalizedText(
            fa: 'عناصر چهارگانه',
            en: 'The Four Elements',
            ar: 'العناصر الأربعة',
            tr: 'Dört Element',
          ),
          LocalizedText(
            fa: 'خاک، آب، آتش، باد',
            en: 'Earth, water, fire, wind',
            ar: 'تراب وماء ونار وهواء',
            tr: 'Toprak, su, ateş, rüzgâr',
          ),
          false,
        ),
        (
          'universe',
          LocalizedText(
            fa: 'فال کائنات',
            en: 'Universe',
            ar: 'فأل الكون',
            tr: 'Evren Falı',
          ),
          LocalizedText(
            fa: 'پیامِ جهان',
            en: 'Message of the cosmos',
            ar: 'رسالة الكون',
            tr: 'Evrenin mesajı',
          ),
          true,
        ),
      ],
    ),
    FortuneGroup(
      LocalizedText(
        fa: 'سنتی و معنوی',
        en: 'Traditional and spiritual',
        ar: 'تقليدي وروحاني',
        tr: 'Geleneksel ve manevi',
      ),
      [
        (
          'tea',
          LocalizedText(
            fa: 'فال چای',
            en: 'Tea Leaves',
            ar: 'قراءة الشاي',
            tr: 'Çay Falı',
          ),
          LocalizedText(
            fa: 'برگ‌های چای',
            en: 'The tea leaves',
            ar: 'أوراق الشاي',
            tr: 'Çay yaprakları',
          ),
          true,
        ),
        (
          'candle',
          LocalizedText(
            fa: 'فال شمع',
            en: 'Candle',
            ar: 'فأل الشمعة',
            tr: 'Mum Falı',
          ),
          LocalizedText(
            fa: 'نور و انرژی',
            en: 'Light and energy',
            ar: 'نور وطاقة',
            tr: 'Işık ve enerji',
          ),
          true,
        ),
        (
          'mirror',
          LocalizedText(
            fa: 'فال آینه',
            en: 'Mirror',
            ar: 'فأل المرآة',
            tr: 'Ayna Falı',
          ),
          LocalizedText(
            fa: 'آینهٔ آینده',
            en: 'Mirror of the future',
            ar: 'مرآة المستقبل',
            tr: 'Geleceğin aynası',
          ),
          true,
        ),
        (
          'lenormand',
          LocalizedText(
            fa: 'فال لنورمان',
            en: 'Lenormand',
            ar: 'اللينورماند',
            tr: 'Lenormand',
          ),
          LocalizedText(
            fa: 'کارت‌های لنورمان',
            en: 'The Lenormand cards',
            ar: 'بطاقات اللينورماند',
            tr: 'Lenormand kartları',
          ),
          true,
        ),
        (
          'rune',
          LocalizedText(
            fa: 'فال رون',
            en: 'Runes',
            ar: 'فأل الرونية',
            tr: 'Rün Falı',
          ),
          LocalizedText(
            fa: 'حروفِ باستان',
            en: 'The ancient letters',
            ar: 'الحروف القديمة',
            tr: 'Kadim harfler',
          ),
          true,
        ),
        (
          'cards',
          LocalizedText(
            fa: 'فال کارتی',
            en: 'Oracle Cards',
            ar: 'فأل البطاقات',
            tr: 'Kart Falı',
          ),
          LocalizedText(
            fa: 'کارت‌های اوراکل',
            en: 'The oracle cards',
            ar: 'بطاقات الأوراكل',
            tr: 'Kehanet kartları',
          ),
          true,
        ),
        (
          'quran',
          LocalizedText(
            fa: 'فال قرآن',
            en: 'Istikhara',
            ar: 'استخارة القرآن',
            tr: 'İstihare',
          ),
          LocalizedText(
            fa: 'استخارهٔ قرآن',
            en: 'Quranic istikhara',
            ar: 'الاستخارة بالقرآن',
            tr: 'Kur\'an istiharesi',
          ),
          true,
        ),
        (
          'tasbih',
          LocalizedText(
            fa: 'فال تسبیح',
            en: 'Prayer Beads',
            ar: 'فأل المسبحة',
            tr: 'Tesbih Falı',
          ),
          LocalizedText(
            fa: 'دانه‌های تسبیح',
            en: 'The tasbih beads',
            ar: 'حبّات المسبحة',
            tr: 'Tesbih taneleri',
          ),
          true,
        ),
        (
          'angel',
          LocalizedText(
            fa: 'پیام فرشتگان',
            en: 'Angel Message',
            ar: 'رسالة الملائكة',
            tr: 'Melek Mesajı',
          ),
          LocalizedText(
            fa: 'پیامِ فرشته',
            en: 'Your angel\'s word',
            ar: 'رسالة ملاكك',
            tr: 'Meleğinin mesajı',
          ),
          true,
        ),
        (
          'spiritanimal',
          LocalizedText(
            fa: 'حیوان روح',
            en: 'Spirit Animal',
            ar: 'حيوان الروح',
            tr: 'Ruh Hayvanı',
          ),
          LocalizedText(
            fa: 'حیوانِ روحِ تو',
            en: 'Your spirit animal',
            ar: 'حيوان روحك',
            tr: 'Senin ruh hayvanın',
          ),
          true,
        ),
        (
          'meditation',
          LocalizedText(
            fa: 'مدیتیشن',
            en: 'Meditation',
            ar: 'التأمّل',
            tr: 'Meditasyon',
          ),
          LocalizedText(
            fa: 'نیت‌گذاری',
            en: 'Setting intention',
            ar: 'غرس النيّة',
            tr: 'Niyet koyma',
          ),
          true,
        ),
      ],
    ),
  ];

  /// The ten the home carousel turns through. Ids only: the card's title,
  /// subtitle and live flag are read back out of the groups above, so a
  /// fortune cannot be shown here without existing in the catalog and a
  /// renamed one cannot say two different things on two screens.
  static const popularIds = <String>[
    'hafez',
    'tarot',
    'coffee',
    'love',
    'dream',
    'abjad',
    'daily',
    'quran',
    'yesno',
    'candle',
  ];

  /// [popularIds] resolved against the catalog, in that order. An id with no
  /// entry is skipped rather than thrown, so a typo costs one slide instead of
  /// the whole home screen.
  static List<FortuneItem> get popular {
    final byId = <String, FortuneItem>{};
    for (final group in groups) {
      for (final item in group.items) {
        byId[item.$1] = item;
      }
    }
    final resolved = <FortuneItem>[];
    for (final id in popularIds) {
      final item = byId[id];
      if (item != null) resolved.add(item);
    }
    return resolved;
  }
}
