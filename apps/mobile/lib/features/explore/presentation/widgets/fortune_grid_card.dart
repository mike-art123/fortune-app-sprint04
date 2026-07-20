import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/foundations/app_opacity.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_definition.dart';

/// One fortune family in the Explore grid. Restrained: a soft accent-tinted
/// emblem, the name, one quiet line. Gold never fills — accents stay thin.
class FortuneGridCard extends StatelessWidget {
  const FortuneGridCard({
    super.key,
    required this.fortune,
    required this.onOpen,
  });

  final FortuneDefinition fortune;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final locale = Localizations.localeOf(context);
    final title = fortune.title.resolve(locale);
    final subtitle = fortune.subtitle.resolve(locale);
    final soon = !fortune.isAvailable;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: c.surfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: c.borderSubtle.withValues(alpha: AppOpacity.hairline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emblem: a quiet accent-tinted circle holding the family mark.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fortune.accent.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fortune.accent,
                    ),
                  ),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (soon) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.strings.comingSoon,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
