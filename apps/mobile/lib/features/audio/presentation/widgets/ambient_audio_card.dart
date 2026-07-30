import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/audio_controller.dart';
import '../../domain/audio_theme.dart';

/// «صدای پس‌زمینه» — the ambient bed, and which one (scope §1).
///
/// The card is absent entirely until a licensed file exists. That is the whole
/// design decision: an empty theme picker, or a switch that turns on silence,
/// would be a promise the app cannot keep.
class AmbientAudioCard extends ConsumerWidget {
  const AmbientAudioCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AudioThemes.hasAny) return const SizedBox.shrink();

    final c = context.fortuneColors;
    final s = context.strings;
    final locale = Localizations.localeOf(context);
    final state = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);

    // The gap belongs to the card, not to the page: when there is nothing to
    // license there is nothing to space out either.
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: GoldBorderContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: state.enabled,
              onChanged: controller.setEnabled,
              title: Text(
                s.audioCardTitle,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                s.audioCardSubtitle,
                style: TextStyle(color: c.textMuted, fontSize: 11),
              ),
              activeTrackColor: c.goldWarm.withValues(alpha: 0.5),
            ),
            if (state.enabled) ...[
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final theme in AudioThemes.available)
                    _ThemeChip(
                      label: theme.label.resolve(locale),
                      selected: theme == state.theme,
                      onTap: () => controller.chooseTheme(theme),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Slider(
                value: state.volume,
                onChanged: controller.setVolume,
                activeColor: c.goldWarm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
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
    return Material(
      color: selected
          ? c.goldWarm.withValues(alpha: 0.18)
          : c.surfaceElevated.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? c.goldWarm : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
