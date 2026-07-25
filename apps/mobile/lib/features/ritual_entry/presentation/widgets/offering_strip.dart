import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/models/localized_text.dart';
import '../../../fortunes/domain/fortune_definition.dart';

/// Interior phase 5 — a bespoke, registry-driven offering element for fortunes
/// whose ritual asks for a *choice* rather than free prose: a birth month, a
/// colour, or a short intent. Tapping a choice seeds the whisper below through
/// [onSeed]; the person can always keep editing that text by hand. This widget
/// only knows how to render a given [FortuneOffering] kind — which fortune
/// shows which strip is decided entirely by the registry.
class OfferingStrip extends StatefulWidget {
  const OfferingStrip({
    super.key,
    required this.offering,
    required this.accent,
    required this.onSeed,
    this.chips = const [],
  });

  final FortuneOffering offering;
  final Color accent;

  /// Called with the chosen value, which becomes the seeded whisper text.
  final void Function(String value) onSeed;

  /// Labels for [FortuneOffering.chips], resolved to the active locale.
  final List<LocalizedText> chips;

  static const List<String> _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<(String, Color)> _colors = [
    ('سرخ', Color(0xFFE5484D)),
    ('نارنجی', Color(0xFFE68A3C)),
    ('طلایی', Color(0xFFE9C46A)),
    ('سبز', Color(0xFF5FBF8F)),
    ('فیروزه‌ای', Color(0xFF4FB6B0)),
    ('آبی', Color(0xFF6FA8DC)),
    ('بنفش', Color(0xFFA78BFA)),
    ('صورتی', Color(0xFFCB6FB0)),
  ];

  @override
  State<OfferingStrip> createState() => _OfferingStripState();
}

class _OfferingStripState extends State<OfferingStrip> {
  String? _selected;

  void _pick(String value) {
    setState(() => _selected = value);
    widget.onSeed(value);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.offering) {
      case FortuneOffering.none:
        return const SizedBox.shrink();
      case FortuneOffering.months:
        return _wrap([
          for (final m in OfferingStrip._months) _pill(m),
        ]);
      case FortuneOffering.chips:
        final locale = Localizations.localeOf(context);
        return _wrap([
          for (final c in widget.chips) _pill(c.resolve(locale)),
        ]);
      case FortuneOffering.colors:
        return _wrap([
          for (final c in OfferingStrip._colors) _swatch(c.$1, c.$2),
        ]);
    }
  }

  Widget _wrap(List<Widget> children) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: children,
    );
  }

  Widget _pill(String label) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selected == label;
    return GestureDetector(
      onTap: () => _pick(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: selected
              ? widget.accent.withValues(alpha: 0.16)
              : c.surfaceElevated.withValues(alpha: 0.4),
          border: Border.all(
            color: selected
                ? widget.accent.withValues(alpha: 0.7)
                : c.borderSubtle.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: selected ? c.textPrimary : c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _swatch(String label, Color color) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selected == label;
    return GestureDetector(
      onTap: () => _pick(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.9),
              border: Border.all(
                color: selected
                    ? c.textPrimary.withValues(alpha: 0.9)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ]
                  : const [],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: selected ? c.textPrimary : c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
