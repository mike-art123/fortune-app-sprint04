import 'package:flutter/material.dart';

import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// One Persian birth-month as a selectable gold pill (scope §16). Shared by
/// onboarding and the profile editor so the two rituals feel identical.
class MonthPill extends StatelessWidget {
  const MonthPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: selected
              ? c.goldWarm.withValues(alpha: 0.16)
              : c.surfaceElevated.withValues(alpha: 0.4),
          border: Border.all(
            color: selected
                ? c.goldWarm.withValues(alpha: 0.7)
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
}
