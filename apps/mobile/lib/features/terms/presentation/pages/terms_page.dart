import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../legal/presentation/widgets/legal_footer.dart';

/// The terms, given a tab of their own.
///
/// They used to sit in a card wedged into the profile page, where they looked
/// like a settings row and read like one. Somebody looking for what this app
/// claims about itself should not have to scroll past notification
/// preferences to find it.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  void _tapNav(BuildContext context, int index) {
    if (index == 0) {
      context.go(AppRoutes.profilePath);
    } else if (index == 1) {
      context.go(AppRoutes.allFortunesPath);
    } else if (index == 2) {
      context.go(AppRoutes.homePath);
    } else if (index == 3) {
      context.go(AppRoutes.historyPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    final lang = Localizations.localeOf(context).languageCode;

    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(s.legalTerms)),
      scrollable: true,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 4,
        onTap: (i) => _tapNav(context, i),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // The whole reason this tab exists, said once and said first.
          GoldBorderContainer(
            glow: true,
            child: Text(
              s.termsHero,
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
            _Section(title: section.title, lines: section.lines),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          const LegalFooter(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.title, this.lines);
  final String title;
  final List<String> lines;
}

List<_TermsSection> _sectionsFor(String lang) {
  return switch (lang) {
    'en' => _sectionsEn,
    'ar' => _sectionsAr,
    'tr' => _sectionsTr,
    _ => _sections,
  };
}

const _sectionsEn = <_TermsSection>[
  _TermsSection('What this app is', [
    'BakhtNegar is made for entertainment and a moment of reflection.',
    'Readings are written from old traditions and carry no scientific, medical '
        'or predictive value.',
    'No fortune here is a certain prediction of the future.',
  ]),
  _TermsSection('Responsibility', [
    'BakhtNegar and its makers accept no responsibility — including legal '
        'responsibility — for your decisions and their outcomes.',
    'Every decision in your life is yours alone.',
    'No fortune should ground important life, medical, legal or financial '
        'decisions.',
  ]),
  _TermsSection('When to see a professional', [
    'For physical or mental health, see a doctor or a therapist.',
    'For legal matters a lawyer; for financial matters a financial advisor.',
    'A fortune replaces none of them.',
  ]),
  _TermsSection('Ads', [
    'Some fortunes open after a short ad; an ad plays only when you choose and '
        'tap it yourself, never automatically.',
    'Ads come from third-party networks (such as AdsGram and Monetag) and '
        'their content belongs to those networks.',
  ]),
  _TermsSection('Intellectual property', [
    'The BakhtNegar name, design, texts and images belong to BakhtNegar.',
    'Readings you take are free for personal use; commercial use of the app '
        'content without permission is not allowed.',
  ]),
  _TermsSection('Limits of use', [
    'Unusual use — automated requests or attempts to bypass limits — may lead '
        'to restricted access.',
    'The free-reading quota and the daily ad cap may change.',
  ]),
  _TermsSection('Acceptance', [
    'Using BakhtNegar means accepting these very terms.',
  ]),
];

const _sectionsAr = <_TermsSection>[
  _TermsSection('ما هذا التطبيق', [
    'صُنع بخت‌نگار للتسلية ولحظة تأمل.',
    'تُكتب الفؤول من تقاليد قديمة ولا قيمة علمية أو طبية أو تنبؤية لها.',
    'لا فأل هنا تنبؤ مؤكد بالمستقبل.',
  ]),
  _TermsSection('المسؤولية', [
    'بخت‌نگار وصانعوه لا يتحملون أي مسؤولية — بما فيها القانونية — عن قراراتك '
        'ونتائجها.',
    'أنت وحدك صاحب القرار في حياتك.',
    'لا ينبغي أن يؤسس أي فأل قرارات حياتية أو طبية أو قانونية أو مالية مهمة.',
  ]),
  _TermsSection('متى تراجع مختصًا', [
    'لصحتك الجسدية أو النفسية راجع طبيبًا أو معالجًا.',
    'للمسائل القانونية محامٍ، وللمالية مستشار مالي.',
    'الفأل لا يحل محل أي منهم.',
  ]),
  _TermsSection('الإعلانات', [
    'تُفتح بعض الفؤول بعد إعلان قصير؛ لا يُعرض الإعلان إلا باختيارك ولمسك، '
        'وليس تلقائيًا أبدًا.',
    'تأتي الإعلانات من شبكات خارجية (مثل AdsGram وMonetag) ومحتواها يخصها.',
  ]),
  _TermsSection('الملكية الفكرية', [
    'اسم بخت‌نگار وتصميمه ونصوصه وصوره ملك لبخت‌نگار.',
    'فؤولك حرة لاستعمالك الشخصي؛ الاستعمال التجاري لمحتوى التطبيق دون إذن غير '
        'مسموح.',
  ]),
  _TermsSection('حدود الاستخدام', [
    'الاستخدام غير المعتاد — كالطلبات الآلية أو محاولات تجاوز الحدود — قد يقيد '
        'وصولك.',
    'قد تتغير حصة الفأل المجاني وسقف الإعلانات اليومي.',
  ]),
  _TermsSection('القبول', [
    'استخدام بخت‌نگار يعني قبول هذه الشروط.',
  ]),
];

const _sections = <_TermsSection>[
  _TermsSection('این برنامه چیست', [
    'بخت‌نگار برای سرگرمی و لحظه‌ای تأمل ساخته شده است.',
    'فال‌ها بر پایهٔ سنت‌های کهن نوشته می‌شوند و ارزش علمی، پزشکی یا '
        'پیش‌بینانه ندارند.',
    'هیچ فالی در این برنامه پیش‌بینیِ قطعیِ آینده نیست.',
  ]),
  _TermsSection('مسئولیت', [
    'بخت‌نگار و سازندگانش هیچ‌گونه مسئولیتی — از جمله مسئولیت حقوقی — در '
        'قبال تصمیم‌های شما و نتیجهٔ آن‌ها نمی‌پذیرند.',
    'تصمیم‌گیرندهٔ تمام امورِ زندگی‌تان خودتان هستید.',
    'هیچ فالی نباید مبنای تصمیم‌های مهمِ زندگی، پزشکی، حقوقی یا مالی باشد.',
  ]),
  _TermsSection('کجا باید به متخصص مراجعه کنی', [
    'برای سلامتی جسمی یا روانی، به پزشک یا روان‌شناس مراجعه کن.',
    'برای مسائل حقوقی به وکیل، و برای مسائل مالی به مشاور مالی.',
    'فال جای هیچ‌کدام از این‌ها نمی‌نشیند.',
  ]),
  _TermsSection('تبلیغات', [
    'بعضی فال‌ها با دیدن یک تبلیغ کوتاه باز می‌شوند؛ تبلیغ فقط با '
        'انتخاب و لمس خودت پخش می‌شود، هرگز خودکار.',
    'تبلیغ‌ها از شبکه‌های شخص ثالث (مانند AdsGram و Monetag) می‌آیند و '
        'محتوایشان با آن شبکه‌هاست.',
  ]),
  _TermsSection('مالکیت معنوی', [
    'نام، طراحی، متن‌ها و تصاویر بخت‌نگار متعلق به بخت‌نگار است.',
    'فال‌هایی که می‌گیری برای استفادهٔ شخصی‌ات آزادند؛ استفادهٔ تجاری از '
        'محتوای برنامه بدون اجازه مجاز نیست.',
  ]),
  _TermsSection('محدودیت استفاده', [
    'استفادهٔ غیرمعمول — مانند درخواست خودکار یا تلاش برای دورزدن '
        'محدودیت‌ها — ممکن است به محدودشدن دسترسی منجر شود.',
    'سهمیهٔ فال رایگان و سقف روزانهٔ تبلیغ ممکن است تغییر کند.',
  ]),
  _TermsSection('پذیرش', [
    'استفاده از بخت‌نگار به معنای پذیرفتن همین شرط‌هاست.',
  ]),
];

const _sectionsTr = <_TermsSection>[
  _TermsSection('Bu uygulama nedir', [
    'BakhtNegar eğlence ve kısa bir düşünme anı için yapıldı.',
    'Fallar eski geleneklerden yazılır; bilimsel, tıbbi ya da öngörüsel değeri '
        'yoktur.',
    'Buradaki hiçbir fal geleceğin kesin tahmini değildir.',
  ]),
  _TermsSection('Sorumluluk', [
    'BakhtNegar ve yapımcıları, kararların ve sonuçları için hukuki olanlar '
        'dahil hiçbir sorumluluk kabul etmez.',
    'Hayatındaki tüm kararlar yalnızca senindir.',
    'Hiçbir fal önemli yaşam, sağlık, hukuk ya da para kararlarına dayanak '
        'olmamalıdır.',
  ]),
  _TermsSection('Ne zaman uzmana gitmeli', [
    'Beden ya da ruh sağlığı için doktora ya da psikoloğa git.',
    'Hukuki konularda avukata, mali konularda danışmana başvur.',
    'Fal bunların hiçbirinin yerini tutmaz.',
  ]),
  _TermsSection('Reklamlar', [
    'Bazı fallar kısa bir reklamla açılır; reklam yalnızca sen seçip dokununca '
        'oynar, asla kendiliğinden.',
    'Reklamlar üçüncü taraf ağlardan (AdsGram, Monetag gibi) gelir; içerikleri '
        'o ağlara aittir.',
  ]),
  _TermsSection('Fikri mülkiyet', [
    'BakhtNegar adı, tasarımı, metinleri ve görselleri markaya aittir.',
    'Aldığın fallar kişisel kullanımına açıktır; içerik izinsiz ticari olarak '
        'kullanılamaz.',
  ]),
  _TermsSection('Kullanım sınırları', [
    'Olağan dışı kullanım — otomatik istekler ya da sınırları aşma denemeleri '
        '— erişimin kısıtlanmasına yol açabilir.',
    'Ücretsiz fal hakkı ve günlük reklam sınırı değişebilir.',
  ]),
  _TermsSection('Kabul', [
    'Uygulamayı kullanmak bu şartları kabul etmektir.',
  ]),
];

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return GoldBorderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.goldWarm,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) ...[
            Text(
              '• $line',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12.5,
                height: 1.9,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
        ],
      ),
    );
  }
}
