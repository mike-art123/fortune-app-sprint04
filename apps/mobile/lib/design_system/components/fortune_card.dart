import 'package:flutter/material.dart';
import '../../design_system/theme/fortune_theme_extension.dart';
import '../foundations/app_opacity.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

enum FortuneCardVariant { standard, elevated, outlined, selected, ritual }

/// Generic surface container. Feature-specific decoration belongs in features,
/// not here (doc 51 §19.3).
class FortuneCard extends StatelessWidget {
  const FortuneCard({
    super.key,
    required this.child,
    this.variant = FortuneCardVariant.standard,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final FortuneCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final (bg, borderColor) = switch (variant) {
      FortuneCardVariant.standard => (c.surfacePrimary, null),
      FortuneCardVariant.elevated => (c.surfaceElevated, null),
      FortuneCardVariant.outlined => (Colors.transparent, c.borderSubtle),
      FortuneCardVariant.selected => (c.surfaceElevated, c.accentSecondary),
      // Gold appears only as a thin line, never as a fill.
      FortuneCardVariant.ritual => (c.surfacePrimary, c.goldWarm),
    };

    final content = Container(
      padding: padding ?? const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor.withValues(alpha: AppOpacity.hairline * 2.5)),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: content,
      ),
    );
  }
}
