import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../shared/models/localized_text.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// A gentle tasseography key — the classic cup signs and what each one hints
/// at — so anyone can read along with the cup. Collapsed by default to keep
/// the ritual calm; one tap reveals it.
const List<(LocalizedText, LocalizedText)> _symbols = [
  (
    LocalizedText(
      fa: 'پرنده',
      en: 'Bird',
      ar: 'طائر',
      tr: 'Kuş',
    ),
    LocalizedText(
      fa: 'خبری خوش در راه است',
      en: 'Good news is on its way',
      ar: 'خبر سعيد في الطريق',
      tr: 'Güzel bir haber yolda',
    ),
  ),
  (
    LocalizedText(
      fa: 'ماهی',
      en: 'Fish',
      ar: 'سمكة',
      tr: 'Balık',
    ),
    LocalizedText(
      fa: 'بخت و فراوانی',
      en: 'Luck and abundance',
      ar: 'حظ ووفرة',
      tr: 'Baht ve bolluk',
    ),
  ),
  (
    LocalizedText(
      fa: 'راه',
      en: 'Road',
      ar: 'طريق',
      tr: 'Yol',
    ),
    LocalizedText(
      fa: 'سفر یا مسیری تازه',
      en: 'A journey or a new path',
      ar: 'سفر أو درب جديد',
      tr: 'Bir yolculuk ya da yeni bir yol',
    ),
  ),
  (
    LocalizedText(
      fa: 'حلقه',
      en: 'Ring',
      ar: 'خاتم',
      tr: 'Yüzük',
    ),
    LocalizedText(
      fa: 'پیوند و تعهد',
      en: 'Union and commitment',
      ar: 'ارتباط والتزام',
      tr: 'Bağ ve bağlılık',
    ),
  ),
  (
    LocalizedText(
      fa: 'قلب',
      en: 'Heart',
      ar: 'قلب',
      tr: 'Kalp',
    ),
    LocalizedText(
      fa: 'عشق و دلبستگی',
      en: 'Love and attachment',
      ar: 'حب وتعلّق',
      tr: 'Aşk ve gönül bağı',
    ),
  ),
  (
    LocalizedText(
      fa: 'درخت',
      en: 'Tree',
      ar: 'شجرة',
      tr: 'Ağaç',
    ),
    LocalizedText(
      fa: 'رشد و ریشه‌دار شدن یک آرزو',
      en: 'A wish growing roots',
      ar: 'أمنية تنمو وتتجذّر',
      tr: 'Kök salan bir dilek',
    ),
  ),
  (
    LocalizedText(
      fa: 'لنگر',
      en: 'Anchor',
      ar: 'مرساة',
      tr: 'Çapa',
    ),
    LocalizedText(
      fa: 'ثبات و آرامش',
      en: 'Stability and calm',
      ar: 'ثبات وسكينة',
      tr: 'Denge ve huzur',
    ),
  ),
  (
    LocalizedText(
      fa: 'کلید',
      en: 'Key',
      ar: 'مفتاح',
      tr: 'Anahtar',
    ),
    LocalizedText(
      fa: 'گشایش و پیدا شدن راه‌حل',
      en: 'An opening; a solution appears',
      ar: 'انفراج وظهور حل',
      tr: 'Ferahlık ve çözümün belirmesi',
    ),
  ),
  (
    LocalizedText(
      fa: 'نامه',
      en: 'Letter',
      ar: 'رسالة',
      tr: 'Mektup',
    ),
    LocalizedText(
      fa: 'پیام یا خبری که می‌رسد',
      en: 'A message on its way',
      ar: 'خبر أو رسالة تصل',
      tr: 'Ulaşacak bir haber ya da mesaj',
    ),
  ),
  (
    LocalizedText(
      fa: 'خوشه',
      en: 'Cluster',
      ar: 'عنقود',
      tr: 'Salkım',
    ),
    LocalizedText(
      fa: 'برکت و شادکامی',
      en: 'Blessing and joy',
      ar: 'بركة وسعادة',
      tr: 'Bereket ve sevinç',
    ),
  ),
  (
    LocalizedText(
      fa: 'کوه',
      en: 'Mountain',
      ar: 'جبل',
      tr: 'Dağ',
    ),
    LocalizedText(
      fa: 'هدفی بلند یا مانعی که پشت سر می‌گذاری',
      en: 'A high aim, or an obstacle you will pass',
      ar: 'هدف عال أو عقبة ستتجاوزها',
      tr: 'Yüce bir hedef ya da aşacağın bir engel',
    ),
  ),
  (
    LocalizedText(
      fa: 'پل',
      en: 'Bridge',
      ar: 'جسر',
      tr: 'Köprü',
    ),
    LocalizedText(
      fa: 'گذر از مرحله‌ای به مرحله‌ی بعد',
      en: 'Crossing into the next chapter',
      ar: 'عبور إلى مرحلة جديدة',
      tr: 'Bir evreden diğerine geçiş',
    ),
  ),
  (
    LocalizedText(
      fa: 'ستاره',
      en: 'Star',
      ar: 'نجمة',
      tr: 'Yıldız',
    ),
    LocalizedText(
      fa: 'امید و اقبالِ روشن',
      en: 'Hope and bright fortune',
      ar: 'أمل وطالع مضيء',
      tr: 'Umut ve parlak talih',
    ),
  ),
  (
    LocalizedText(
      fa: 'گل',
      en: 'Flower',
      ar: 'زهرة',
      tr: 'Çiçek',
    ),
    LocalizedText(
      fa: 'شکوفایی و دلگرمی',
      en: 'Blossoming and heart-ease',
      ar: 'ازدهار وطمأنينة',
      tr: 'Açan baht ve gönül ferahlığı',
    ),
  ),
  (
    LocalizedText(
      fa: 'ماه',
      en: 'Moon',
      ar: 'قمر',
      tr: 'Ay',
    ),
    LocalizedText(
      fa: 'رؤیا و الهام',
      en: 'Dream and inspiration',
      ar: 'رؤيا وإلهام',
      tr: 'Rüya ve ilham',
    ),
  ),
  (
    LocalizedText(
      fa: 'پرچم',
      en: 'Flag',
      ar: 'راية',
      tr: 'Bayrak',
    ),
    LocalizedText(
      fa: 'نقطه‌ی عطف و یک پیروزیِ کوچک',
      en: 'A turning point; a small victory',
      ar: 'نقطة تحوّل ونصر صغير',
      tr: 'Bir dönüm noktası; küçük bir zafer',
    ),
  ),
];

class CoffeeSymbolGuide extends StatefulWidget {
  const CoffeeSymbolGuide({super.key, required this.accent});

  final Color accent;

  @override
  State<CoffeeSymbolGuide> createState() => _CoffeeSymbolGuideState();
}

class _CoffeeSymbolGuideState extends State<CoffeeSymbolGuide> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: c.surfaceElevated.withValues(alpha: 0.5),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.local_cafe, size: 20, color: widget.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s.coffeeGuideTitle,
                      style: textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_open) _Body(intro: s.coffeeGuideIntro),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.intro});

  final String intro;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            intro,
            style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final symbol in _symbols)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      symbol.$1.resolve(locale),
                      style: textTheme.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      symbol.$2.resolve(locale),
                      style: textTheme.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
