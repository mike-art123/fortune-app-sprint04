import 'package:flutter/material.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// The one-time notice before the very first reading (publisher policy):
/// readings are entertainment, not advice. Returns true once acknowledged.
Future<bool> showFirstReadingDisclaimer(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => const _DisclaimerSheet(),
  );
  return ok ?? false;
}

class _DisclaimerSheet extends StatelessWidget {
  const _DisclaimerSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    final lang = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: Container(
        margin: const EdgeInsetsDirectional.all(AppSpacing.sm),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoldBorderContainer(
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.disclaimerBody,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: c.textPrimary,
                      height: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lang != 'en') ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Readings are provided for entertainment and personal '
                      'reflection only and should not be considered '
                      'professional advice.',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11.5,
                        height: 1.7,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FortuneButton(
              label: s.legalUnderstood,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
