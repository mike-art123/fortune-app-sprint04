import 'package:flutter/material.dart';
import '../../app/localization/app_strings.dart';
import '../../design_system/components/fortune_card.dart';
import '../../design_system/foundations/app_spacing.dart';
import '../../design_system/motion/fortune_fade_transition.dart';

/// FOUNDATION PLACEHOLDER — intentionally restrained. This is NOT the final
/// feature UI and must be replaced during each feature's own phase.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, required this.title, this.detail});
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return FortuneFadeIn(
      child: Center(
        child: FortuneCard(
          variant: FortuneCardVariant.outlined,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.strings.placeholderNotice,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
