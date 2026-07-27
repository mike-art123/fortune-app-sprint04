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
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A widget that shares the heading's row and takes the space the title does
  /// not need. Used for the fortune search, which belongs beside a heading the
  /// reader can actually see rather than alone above one.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final titleStyle = TextStyle(
      color: c.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const _GoldBar(),
          const SizedBox(width: AppSpacing.xs),
          if (trailing == null)
            Expanded(child: Text(title, style: titleStyle))
          else ...[
            // Deliberately not Flexible. A loose flex child hands its unused
            // share back to the row's alignment, not to its neighbour, which
            // in RTL would leave a dead gap at the left edge instead of a
            // search field that reaches it. Inflexible text plus one Expanded
            // divides the row exactly.
            Text(title, style: titleStyle),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: trailing!),
          ],
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
