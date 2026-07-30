import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('قوانین')),
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
              'بخت‌نگار هیچ‌گونه مسئولیتی نمی‌پذیرد.\n'
              'این برنامه فقط یک فال است، و تصمیم‌گیرندهٔ تمام امورِ '
              'زندگی‌تان خودتان هستید.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: c.textPrimary,
                height: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final section in _sections) ...[
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
