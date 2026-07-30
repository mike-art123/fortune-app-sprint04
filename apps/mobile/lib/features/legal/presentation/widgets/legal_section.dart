import 'package:flutter/material.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// One titled block of informational lines, in the app's calm voice — the
/// same shape the terms page established, shared by every legal page.
class LegalSection extends StatelessWidget {
  const LegalSection({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return GoldBorderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.goldWarm,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) ...[
            Text(
              '• $line',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12.5,
                height: 1.9,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
        ],
      ),
    );
  }
}
