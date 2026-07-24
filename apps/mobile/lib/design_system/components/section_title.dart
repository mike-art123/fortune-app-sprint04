import 'package:flutter/material.dart';

import '../foundations/app_gradients.dart';
import '../foundations/app_spacing.dart';
import '../theme/fortune_theme_extension.dart';

/// Section header: a gold accent bar + title, with an optional trailing action
/// such as «مشاهده همه». RTL-aware.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const _GoldBar(),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(color: c.goldWarm, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoldBar extends StatelessWidget {
  const _GoldBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 18,
      decoration: const BoxDecoration(
        gradient: AppGradients.goldSheen,
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}
