import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/models/localized_text.dart';
import '../../../fortunes/domain/fortune_definition.dart';
import '../../../profile/domain/user_profile.dart';

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

  static const List<(LocalizedText, Color)> _colors = [
    (
      LocalizedText(
        fa: 'سرخ',
        en: 'Red',
        ar: 'أحمر',
        tr: 'Kırmızı',
      ),
      Color(0xFFE5484D),
    ),
    (
      LocalizedText(
        fa: 'نارنجی',
        en: 'Orange',
        ar: 'برتقالي',
        tr: 'Turuncu',
      ),
      Color(0xFFE68A3C),
    ),
    (
      LocalizedText(
        fa: 'طلایی',
        en: 'Gold',
        ar: 'ذهبي',
        tr: 'Altın',
      ),
      Color(0xFFE9C46A),
    ),
    (
      LocalizedText(
        fa: 'سبز',
        en: 'Green',
        ar: 'أخضر',
        tr: 'Yeşil',
      ),
      Color(0xFF5FBF8F),
    ),
    (
      LocalizedText(
        fa: 'فیروزه‌ای',
        en: 'Turquoise',
        ar: 'فيروزي',
        tr: 'Turkuaz',
      ),
      Color(0xFF4FB6B0),
    ),
    (
      LocalizedText(
        fa: 'آبی',
        en: 'Blue',
        ar: 'أزرق',
        tr: 'Mavi',
      ),
      Color(0xFF6FA8DC),
    ),
    (
      LocalizedText(
        fa: 'بنفش',
        en: 'Purple',
        ar: 'بنفسجي',
        tr: 'Mor',
      ),
      Color(0xFFA78BFA),
    ),
    (
      LocalizedText(
        fa: 'صورتی',
        en: 'Pink',
        ar: 'وردي',
        tr: 'Pembe',
      ),
      Color(0xFFCB6FB0),
    ),
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
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    switch (widget.offering) {
      case FortuneOffering.none:
        return const SizedBox.shrink();
      case FortuneOffering.months:
        return _wrap([
          for (final m in kBirthMonths) _pill(monthLabel(m, lang)),
        ]);
      case FortuneOffering.chips:
        return _wrap([
          for (final c in widget.chips) _pill(c.resolve(locale)),
        ]);
      case FortuneOffering.colors:
        return _wrap([
          for (final c in OfferingStrip._colors)
            _swatch(c.$1.resolve(locale), c.$2),
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
