import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../widgets/legal_footer.dart';
import '../widgets/legal_section.dart';

/// About — what BakhtNegar is, in its own voice: the mission, the rituals,
/// how the interpretation works, and the disclaimer said plainly.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    final lang = Localizations.localeOf(context).languageCode;

    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(s.aboutTitle)),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            glow: true,
            child: Text(
              s.aboutHero,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: c.textPrimary,
                height: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final section in _sectionsFor(lang)) ...[
            LegalSection(title: section.$1, lines: section.$2),
            const SizedBox(height: AppSpacing.sm),
          ],
          GoldBorderContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.disclaimerBody,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: c.textPrimary,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lang != 'en') ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Readings are provided for entertainment and personal '
                    'reflection only and should not be considered '
                    'professional advice.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11.5,
                      height: 1.7,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const LegalFooter(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

List<(String, List<String>)> _sectionsFor(String lang) {
  return switch (lang) {
    'en' => _sectionsEn,
    'ar' => _sectionsAr,
    'tr' => _sectionsTr,
    _ => _sections,
  };
}

const _sections = <(String, List<String>)>[
  (
    'مأموریت ما',
    [
      'سنت‌های کهنِ فال را با احترام، زیبایی و آرامش به تجربه‌ای امروزی تبدیل '
          'کنیم.',
      'هر فال یک آیین کوتاه است: نیت می‌کنی، لحظه‌ای درنگ می‌کنی، و خوانشی '
          'برای تأمل می‌گیری.',
    ],
  ),
  (
    'چه چیزهایی این‌جاست',
    [
      'فال حافظ — با غزل‌های واقعی از دیوان حافظ.',
      'تاروت — با ۷۸ کارت کامل و معنای راست و وارونه.',
      'فال قهوه — با خواندن نشانه‌های فنجان تو.',
      'استخاره و تفأل — با یادآوریِ جایگاه معنوی آن.',
      'تعبیر خواب، فال روزانه، لنورمان، رون، و ده‌ها فال دیگر.',
    ],
  ),
  (
    'تفسیر هوشمند',
    [
      'منبعِ هر فال (غزل، کارت، نشانه) نخست به‌صورت قطعی انتخاب می‌شود؛ هوش '
          'مصنوعی فقط همان را برای تو تفسیر می‌کند.',
      'نیت تو خصوصی می‌ماند: فقط برای ساختن همان فال استفاده می‌شود و در '
          'گزارش‌ها ثبت نمی‌شود.',
    ],
  ),
];

const _sectionsEn = <(String, List<String>)>[
  (
    'Our mission',
    [
      'To turn the old traditions of fortune-telling into a modern experience, '
          'with respect, beauty and calm.',
      'Every fortune is a short ritual: you set an intention, pause a moment, '
          'and receive a reading to reflect on.',
    ],
  ),
  (
    'What lives here',
    [
      'Hafez — with real ghazals from the Divan of Hafez.',
      'Tarot — all 78 cards, with upright and reversed meanings.',
      'Coffee — reading the signs of your own cup.',
      'Istikhara — with its spiritual place remembered.',
      'Dream interpretation, the daily fortune, Lenormand, runes, and dozens '
          'more.',
    ],
  ),
  (
    'Smart interpretation',
    [
      'The source of each fortune (ghazal, card, sign) is chosen '
          'deterministically first; the AI only interprets that very source '
          'for you.',
      'Your intention stays private: used only to craft that reading, and '
          'never recorded in reports.',
    ],
  ),
];

const _sectionsAr = <(String, List<String>)>[
  (
    'مهمتنا',
    [
      'أن نحوّل تقاليد الفأل العريقة إلى تجربة عصرية، باحترام وجمال وسكينة.',
      'كل فأل طقس قصير: تنوي، تتمهل لحظة، وتتلقى قراءة للتأمل.',
    ],
  ),
  (
    'ماذا تجد هنا',
    [
      'فأل حافظ — بغزليات حقيقية من ديوانه.',
      'التاروت — 78 بطاقة كاملة بمعانيها المستقيمة والمقلوبة.',
      'قراءة الفنجان — من علامات فنجانك أنت.',
      'الاستخارة — مع تذكّر مقامها الروحي.',
      'تفسير الأحلام وفأل اليوم واللينورمان والرونية وعشرات غيرها.',
    ],
  ),
  (
    'التفسير الذكي',
    [
      'يُختار مصدر كل فأل (الغزل، البطاقة، العلامة) أولًا بشكل قطعي؛ ثم يفسر '
          'الذكاء الاصطناعي ذلك المصدر نفسه لك.',
      'نيتك تبقى خاصة: تُستخدم لصنع ذلك الفأل فقط ولا تُسجل في التقارير.',
    ],
  ),
];

const _sectionsTr = <(String, List<String>)>[
  (
    'Misyonumuz',
    [
      'Kadim fal geleneklerini saygı, güzellik ve dinginlikle bugüne taşımak.',
      'Her fal kısa bir ritüeldir: niyet edersin, bir an durursun, düşünmek '
          'için bir yorum alırsın.',
    ],
  ),
  (
    'Burada neler var',
    [
      'Hafız falı — divandan gerçek gazellerle.',
      'Tarot — düz ve ters anlamlarıyla 78 kartın tamamı.',
      'Kahve falı — kendi fincanının işaretlerinden.',
      'İstihare — manevi yeri hatırlatılarak.',
      'Rüya tabiri, günlük fal, Lenormand, rünler ve onlarcası.',
    ],
  ),
  (
    'Akıllı yorum',
    [
      'Her falın kaynağı (gazel, kart, işaret) önce belirlenimci olarak '
          'seçilir; yapay zekâ yalnızca o kaynağı senin için yorumlar.',
      'Niyetin gizli kalır: yalnızca o falı üretmekte kullanılır, raporlara '
          'geçmez.',
    ],
  ),
];
