import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';

/// A rounded panel with a gold hairline border, the premium dark card fill and
/// an optional soft gold glow — the building block for luxury surfaces.
class GoldBorderContainer extends StatelessWidget {
  const GoldBorderContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.xl,
    this.glow = false,
    this.gradient = AppGradients.cardLuxe,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.42)),
        boxShadow: glow ? AppEffects.goldGlow : null,
      ),
      child: child,
    );
  }
}
