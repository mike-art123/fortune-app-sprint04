import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// A gentle tasseography key — the classic cup signs and what each one hints
/// at — so anyone can read along with the cup. Collapsed by default to keep
/// the ritual calm; one tap reveals it.
const List<(String, String)> _symbols = [
  ('پرنده', 'خبری خوش در راه است'),
  ('ماهی', 'بخت و فراوانی'),
  ('راه', 'سفر یا مسیری تازه'),
  ('حلقه', 'پیوند و تعهد'),
  ('قلب', 'عشق و دلبستگی'),
  ('درخت', 'رشد و ریشه‌دار شدن یک آرزو'),
  ('لنگر', 'ثبات و آرامش'),
  ('کلید', 'گشایش و پیدا شدن راه‌حل'),
  ('نامه', 'پیام یا خبری که می‌رسد'),
  ('خوشه', 'برکت و شادکامی'),
  ('کوه', 'هدفی بلند یا مانعی که پشت سر می‌گذاری'),
  ('پل', 'گذر از مرحله‌ای به مرحله‌ی بعد'),
  ('ستاره', 'امید و اقبالِ روشن'),
  ('گل', 'شکوفایی و دلگرمی'),
  ('ماه', 'رؤیا و الهام'),
  ('پرچم', 'نقطه‌ی عطف و یک پیروزیِ کوچک'),
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
                    child: Text(symbol.$1, style: textTheme.labelLarge),
                  ),
                  Expanded(
                    child: Text(
                      symbol.$2,
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
