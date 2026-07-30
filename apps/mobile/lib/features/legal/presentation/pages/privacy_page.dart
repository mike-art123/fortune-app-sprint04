import 'package:flutter/material.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../widgets/legal_footer.dart';
import '../widgets/legal_section.dart';

/// Privacy — what is collected, what is not, and the reader's rights.
/// Written to match what the app actually does; nothing aspirational.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;

    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('حریم خصوصی')),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            glow: true,
            child: Text(
              'حریم خصوصی تو برای ما جدی است.\n'
              'کمترین دادهٔ ممکن، فقط برای کارکردن خودِ فال.',
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
            LegalSection(title: section.$1, lines: section.$2),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            'آخرین به‌روزرسانی: تیر ۱۴۰۵ (July 2026)',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const LegalFooter(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

const _sections = <(String, List<String>)>[
  (
    'ورود و هویت',
    [
      'در مینی‌اپ تلگرام، هویت تو از خودِ تلگرام می‌آید: شناسهٔ عددی و '
          'نام نمایشی. رمز عبوری وجود ندارد و ما به حساب تلگرامت '
          'دسترسی نداریم.',
      'در نسخهٔ مستقل (مثل اندروید)، ورود مهمان با یک شناسهٔ تصادفیِ '
          'دستگاه انجام می‌شود؛ نه شماره تلفن می‌خواهیم نه ایمیل.',
    ],
  ),
  (
    'چه چیزی ذخیره می‌شود',
    [
      'فال‌هایی که می‌گیری و تاریخچه‌شان، تا بتوانی دوباره بخوانی‌شان.',
      'تنظیمات برنامه (زبان، صدا، اعلان‌ها).',
      'نیت‌ها خصوصی‌اند: فقط برای ساختن همان فال استفاده می‌شوند و '
          'متنشان هرگز در گزارش‌ها و لاگ‌ها ثبت نمی‌شود.',
    ],
  ),
  (
    'تحلیل و آمار',
    [
      'فقط رویدادهای فنیِ بی‌نام و بدون محتوا (مثل «صفحه باز شد») برای '
          'بهترکردن برنامه ثبت می‌شود.',
      'متن نیت، متن فال و هر چیز شخصی هرگز بخشی از آمار نیست.',
    ],
  ),
  (
    'تبلیغات',
    [
      'تبلیغ فقط وقتی نمایش داده می‌شود که خودت دکمهٔ «دیدن تبلیغ» را '
          'بزنی؛ هیچ تبلیغی خودکار پخش نمی‌شود.',
      'شبکه‌های تبلیغ (AdsGram و Monetag) حین نمایش تبلیغ طبق '
          'سیاست‌های خودشان ممکن است شناسه‌های فنی دریافت کنند.',
      'ما هیچ دادهٔ شخصی‌ای به شبکه‌های تبلیغ نمی‌فروشیم.',
    ],
  ),
  (
    'کوکی و ذخیرهٔ محلی',
    [
      'کوکیِ ردیابی نداریم. روی دستگاه تو فقط تنظیمات و کلید ورود '
          'به‌صورت محلی نگه داشته می‌شود.',
      'با پاک‌کردن دادهٔ برنامه یا مرورگر، این موارد هم پاک می‌شوند.',
    ],
  ),
  (
    'حقوق تو (GDPR)',
    [
      'حق دسترسی، اصلاح و حذف داده‌هایت را داری.',
      'برای هرکدام کافی است از صفحهٔ «تماس» پیام بدهی؛ در اسرع وقت '
          'انجام می‌شود.',
    ],
  ),
  (
    'کاربران کالیفرنیا (CCPA)',
    [
      'دادهٔ شخصی تو فروخته یا «به اشتراک گذاشته» نمی‌شود؛ بنابراین '
          'چیزی برای انصراف (Do Not Sell) وجود ندارد.',
    ],
  ),
  (
    'کودکان',
    [
      'بخت‌نگار برای مخاطب عمومی است و آگاهانه از کودکان زیر ۱۳ سال '
          'داده جمع نمی‌کند.',
    ],
  ),
  (
    'تغییرات',
    [
      'هر تغییر مهمی در همین صفحه اعلام می‌شود؛ تاریخ آخرین '
          'به‌روزرسانی پایین صفحه است.',
    ],
  ),
];
