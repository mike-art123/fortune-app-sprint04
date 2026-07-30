import 'package:flutter/material.dart';
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

    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('درباره بخت‌نگار')),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            glow: true,
            child: Text(
              'بخت‌نگار — فال و اسرارِ زندگی.\n'
              'یک لحظهٔ آرام برای خودت، به زبان فارسی.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: c.textPrimary,
                height: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const LegalSection(
            title: 'مأموریت ما',
            lines: [
              'سنت‌های کهنِ فال را با احترام، زیبایی و آرامش به تجربه‌ای '
                  'امروزی تبدیل کنیم.',
              'هر فال یک آیین کوتاه است: نیت می‌کنی، لحظه‌ای درنگ می‌کنی، '
                  'و خوانشی برای تأمل می‌گیری.',
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const LegalSection(
            title: 'چه چیزهایی این‌جاست',
            lines: [
              'فال حافظ — با غزل‌های واقعی از دیوان حافظ.',
              'تاروت — با ۷۸ کارت کامل و معنای راست و وارونه.',
              'فال قهوه — با خواندن نشانه‌های فنجان تو.',
              'استخاره و تفأل — با یادآوریِ جایگاه معنوی آن.',
              'تعبیر خواب، فال روزانه، لنورمان، رون، و ده‌ها فال دیگر.',
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const LegalSection(
            title: 'تفسیر هوشمند',
            lines: [
              'منبعِ هر فال (غزل، کارت، نشانه) نخست به‌صورت قطعی انتخاب '
                  'می‌شود؛ هوش مصنوعی فقط همان را برای تو تفسیر می‌کند.',
              'نیت تو خصوصی می‌ماند: فقط برای ساختن همان فال استفاده '
                  'می‌شود و در گزارش‌ها ثبت نمی‌شود.',
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'فال‌های بخت‌نگار صرفاً برای سرگرمی و تأمل شخصی ارائه '
                  'می‌شوند و نباید مبنای تصمیم‌های مهم زندگی قرار گیرند.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: c.textPrimary,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
