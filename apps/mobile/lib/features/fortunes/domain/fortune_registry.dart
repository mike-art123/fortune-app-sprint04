import '../../../design_system/foundations/app_colors.dart';
import '../../../shared/models/localized_text.dart';
import 'fortune_definition.dart';

/// Source of truth for every fortune family (Sprint 01).
/// Adding a fortune here is the ONLY change needed for it to appear in
/// Explore and gain a working Ritual Entry.
abstract final class FortuneRegistry {
  static const List<FortuneDefinition> all = [
    FortuneDefinition(
      id: 'hafez',
      accent: CategoryAccents.hafez,
      inputKind: FortuneInputKind.intention,
      title: LocalizedText(fa: 'فال حافظ', en: 'Hafez'),
      subtitle: LocalizedText(fa: 'نیت کن و از دیوان بپرس', en: 'Hold an intention, ask the Divan'),
      ritualLine: LocalizedText(fa: 'نیتت را در دل نگه دار.', en: 'Hold your intention in your heart.'),
      placeholder: LocalizedText(fa: '…یا این‌جا با خودت بگو', en: '…or whisper it here'),
      cta: LocalizedText(fa: 'فال حافظ را باز کن', en: 'Open the Hafez reading'),
      pace: RitualPace(enter: Duration(milliseconds: 500), step: Duration(milliseconds: 140)),
    ),
    FortuneDefinition(
      id: 'tarot',
      accent: CategoryAccents.tarot,
      inputKind: FortuneInputKind.intention,
      title: LocalizedText(fa: 'تاروت', en: 'Tarot'),
      subtitle: LocalizedText(fa: 'پرسشی که می‌خواهی روشن شود', en: 'A question seeking light'),
      ritualLine: LocalizedText(
        fa: 'به پرسشی فکر کن که می‌خواهی روشن شود.',
        en: 'Think of the question you want illuminated.',
      ),
      placeholder: LocalizedText(fa: '…یا این‌جا بپرس', en: '…or ask it here'),
      cta: LocalizedText(fa: 'کارت‌ها را بکش', en: 'Draw the cards'),
      pace: RitualPace(enter: Duration(milliseconds: 600), step: Duration(milliseconds: 170)),
    ),
    FortuneDefinition(
      id: 'dream',
      accent: CategoryAccents.dream,
      inputKind: FortuneInputKind.longText,
      title: LocalizedText(fa: 'تعبیر خواب', en: 'Dream'),
      subtitle: LocalizedText(fa: 'خوابت را آرام تعریف کن', en: 'Tell your dream, gently'),
      ritualLine: LocalizedText(
        fa: 'خوابت را همان‌طور که به یادت مانده، آرام تعریف کن.',
        en: 'Tell your dream just as you remember it, gently.',
      ),
      placeholder: LocalizedText(fa: 'از هر جایی که یادت می‌آید شروع کن…', en: 'Start anywhere you remember…'),
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
      pace: RitualPace(enter: Duration(milliseconds: 660), step: Duration(milliseconds: 180)),
    ),
    FortuneDefinition(
      id: 'love',
      accent: CategoryAccents.love,
      inputKind: FortuneInputKind.twoNames,
      title: LocalizedText(fa: 'فال عشق', en: 'Love'),
      subtitle: LocalizedText(fa: 'دو نام، یک پیوند', en: 'Two names, one bond'),
      ritualLine: LocalizedText(fa: 'دو نام، یک پیوند.', en: 'Two names, one bond.'),
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
      pace: RitualPace(enter: Duration(milliseconds: 460), step: Duration(milliseconds: 130)),
    ),
    FortuneDefinition(
      id: 'coffee',
      accent: CategoryAccents.coffee,
      inputKind: FortuneInputKind.photo,
      title: LocalizedText(fa: 'فال قهوه', en: 'Coffee'),
      subtitle: LocalizedText(fa: 'رازهای تهِ فنجان', en: 'Secrets at the bottom of the cup'),
      ritualLine: LocalizedText(
        fa: 'فنجانت را وارونه کن و یک عکس بگیر.',
        en: 'Turn your cup over and take a photo.',
      ),
      cta: LocalizedText(fa: 'فنجان را بخوان', en: 'Read the cup'),
      availability: FortuneAvailability.soon,
      pace: RitualPace(enter: Duration(milliseconds: 500), step: Duration(milliseconds: 150)),
    ),
  ];

  static FortuneDefinition? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
