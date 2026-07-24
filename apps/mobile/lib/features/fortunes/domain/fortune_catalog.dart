/// Browse catalog for the «همه فال‌ها» grid.
///
/// A single entry: (id, faTitle, faSubtitle, isLive). `id` matches
/// assets/fortunes/<id>.jpg and, when live, a FortuneRegistry id. Only the
/// four backend-backed fortunes are live (POST /readings); the rest are shown
/// as «به‌زودی» with a disabled action — never as dead cards.
typedef FortuneItem = (String, String, String, bool);

/// A titled section of the catalog.
class FortuneGroup {
  const FortuneGroup(this.title, this.items);

  final String title;
  final List<FortuneItem> items;
}

/// The full 40-fortune catalog, grouped by theme.
abstract final class FortuneCatalog {
  static const groups = <FortuneGroup>[
    FortuneGroup('فال‌های محبوب', [
      ('hafez', 'فال حافظ', 'با غزل حافظ', true),
      ('coffee', 'فال قهوه', 'با تفسیر کامل', false),
      ('tarot', 'تاروت', 'کارت‌های تاروت', true),
      ('dream', 'تعبیر خواب', 'معنی رویاها', true),
      ('love', 'فال عشق', 'روابط عاطفی', true),
      ('abjad', 'فال ابجد', 'حروف و اعداد', false),
    ]),
    FortuneGroup('عشق و روابط', [
      ('marriage', 'فال ازدواج', 'آیندهٔ ازدواج', false),
      ('child', 'فال فرزند', 'فرزند داری؟', false),
      ('friendship', 'فال دوستی', 'دوستانِ واقعی', false),
      ('separation', 'فال جدایی', 'پایانِ رابطه؟', false),
      ('reconcile', 'فال آشتی', 'بازگشتِ او', false),
      ('name', 'فال اسم', 'رازِ نامت', false),
    ]),
    FortuneGroup('کار و آینده', [
      ('job', 'فال شغل', 'آیندهٔ کاری', false),
      ('money', 'فال مالی', 'ثروت و پول', false),
      ('travel', 'فال سفر', 'سفر در راه؟', false),
      ('future', 'فال آینده', 'در انتظارِ من', false),
      ('message', 'فال پیام', 'پیامی در راه', false),
      ('intention', 'فال نیت', 'نیتِ قلبی', false),
    ]),
    FortuneGroup('شانس و انرژی', [
      ('yesno', 'بله یا خیر', 'پاسخِ سریع', false),
      ('luckynumber', 'عدد شانس', 'عددِ خوش‌یمن', false),
      ('luckycolor', 'رنگ شانس', 'رنگِ امروز', false),
      ('luckystone', 'سنگ شانس', 'سنگِ متولد', false),
      ('luckyflower', 'گل شانس', 'گلِ تو', false),
      ('dailytalisman', 'طلسم روزانه', 'حفاظت و انرژی', false),
      ('lots', 'فال قرعه', 'قرعه و شانس', false),
    ]),
    FortuneGroup('آسترولوژی', [
      ('birthmonth', 'ماه تولد', 'طالع و شخصیت', false),
      ('daily', 'فال روزانه', 'ویژهٔ امروز', false),
      ('elements', 'عناصر چهارگانه', 'خاک، آب، آتش، باد', false),
      ('universe', 'فال کائنات', 'پیامِ جهان', false),
    ]),
    FortuneGroup('سنتی و معنوی', [
      ('tea', 'فال چای', 'برگ‌های چای', false),
      ('candle', 'فال شمع', 'نور و انرژی', false),
      ('mirror', 'فال آینه', 'آینهٔ آینده', false),
      ('lenormand', 'فال لنورمان', 'کارت‌های لنورمان', false),
      ('rune', 'فال رون', 'حروفِ باستان', false),
      ('cards', 'فال کارتی', 'کارت‌های اوراکل', false),
      ('quran', 'فال قرآن', 'استخارهٔ قرآن', false),
      ('tasbih', 'فال تسبیح', 'دانه‌های تسبیح', false),
      ('angel', 'پیام فرشتگان', 'پیامِ فرشته', false),
      ('spiritanimal', 'حیوان روح', 'حیوانِ روحِ تو', false),
      ('meditation', 'مدیتیشن', 'نیت‌گذاری', false),
    ]),
  ];
}
