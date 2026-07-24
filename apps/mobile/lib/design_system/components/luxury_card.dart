import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

/// A tappable premium surface: dark gradient fill, gold hairline border, an
/// optional gold glow and an ink ripple. Wraps any content (cards, tiles).
class LuxuryCard extends StatelessWidget {
  const LuxuryCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.xl,
    this.glow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.cardLuxe,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.42)),
        boxShadow: glow ? AppEffects.goldGlow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
