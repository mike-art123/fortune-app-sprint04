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
      ('abjad', 'فال ابجد', 'حروف و اعداد', true),
    ]),
    FortuneGroup('عشق و روابط', [
      ('marriage', 'فال ازدواج', 'آیندهٔ ازدواج', true),
      ('child', 'فال فرزند', 'فرزند داری؟', true),
      ('friendship', 'فال دوستی', 'دوستانِ واقعی', true),
      ('separation', 'فال جدایی', 'پایانِ رابطه؟', true),
      ('reconcile', 'فال آشتی', 'بازگشتِ او', true),
      ('name', 'فال اسم', 'رازِ نامت', true),
    ]),
    FortuneGroup('کار و آینده', [
      ('job', 'فال شغل', 'آیندهٔ کاری', true),
      ('money', 'فال مالی', 'ثروت و پول', true),
      ('travel', 'فال سفر', 'سفر در راه؟', true),
      ('future', 'فال آینده', 'در انتظارِ من', true),
      ('message', 'فال پیام', 'پیامی در راه', true),
      ('intention', 'فال نیت', 'نیتِ قلبی', true),
    ]),
    FortuneGroup('شانس و انرژی', [
      ('yesno', 'بله یا خیر', 'پاسخِ سریع', true),
      ('luckynumber', 'عدد شانس', 'عددِ خوش‌یمن', true),
      ('luckycolor', 'رنگ شانس', 'رنگِ امروز', true),
      ('luckystone', 'سنگ شانس', 'سنگِ متولد', true),
      ('luckyflower', 'گل شانس', 'گلِ تو', true),
      ('dailytalisman', 'طلسم روزانه', 'حفاظت و انرژی', true),
      ('lots', 'فال قرعه', 'قرعه و شانس', true),
    ]),
    FortuneGroup('آسترولوژی', [
      ('birthmonth', 'ماه تولد', 'طالع و شخصیت', true),
      ('daily', 'فال روزانه', 'ویژهٔ امروز', true),
      ('elements', 'عناصر چهارگانه', 'خاک، آب، آتش، باد', false),
      ('universe', 'فال کائنات', 'پیامِ جهان', true),
    ]),
    FortuneGroup('سنتی و معنوی', [
      ('tea', 'فال چای', 'برگ‌های چای', true),
      ('candle', 'فال شمع', 'نور و انرژی', true),
      ('mirror', 'فال آینه', 'آینهٔ آینده', true),
      ('lenormand', 'فال لنورمان', 'کارت‌های لنورمان', true),
      ('rune', 'فال رون', 'حروفِ باستان', true),
      ('cards', 'فال کارتی', 'کارت‌های اوراکل', true),
      ('quran', 'فال قرآن', 'استخارهٔ قرآن', true),
      ('tasbih', 'فال تسبیح', 'دانه‌های تسبیح', true),
      ('angel', 'پیام فرشتگان', 'پیامِ فرشته', true),
      ('spiritanimal', 'حیوان روح', 'حیوانِ روحِ تو', true),
      ('meditation', 'مدیتیشن', 'نیت‌گذاری', true),
    ]),
  ];
}
