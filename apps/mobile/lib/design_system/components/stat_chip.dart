import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import '../theme/fortune_theme_extension.dart';

/// A compact pill showing an icon + value (+ optional label): coins, gems and
/// profile statistics. Gold-bordered on the premium dark fill.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String? label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.cardLuxe,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? c.goldWarm),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.xxs),
            Text(label!, style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
