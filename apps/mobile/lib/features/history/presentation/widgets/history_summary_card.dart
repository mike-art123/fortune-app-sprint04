import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../application/history_summary_controller.dart';
import '../../domain/history_recap.dart';
import '../../domain/history_summary.dart';

/// «نگاهی به گذشته» — what this stretch of time looked like (scope §6).
///
/// It sits above the journal and never in front of it: while the summary is
/// being fetched, or if it never arrives, the readings themselves are already
/// on screen and nothing is missing.
class HistorySummaryCard extends ConsumerWidget {
  const HistorySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    final locale = Localizations.localeOf(context);
    final range = ref.watch(summaryRangeProvider);
    final summary = ref.watch(historySummaryProvider).valueOrNull;
    // Null in Persian, where the server's sentence is already the right one.
    final recap = summary == null ? null : recapFor(summary, locale);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: GoldBorderContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.historyLookback,
                    style: textTheme.titleMedium?.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                for (final option in SummaryRange.values)
                  _RangeChip(
                    label: option.label.resolve(locale),
                    selected: option == range,
                    onTap: () =>
                        ref.read(summaryRangeProvider.notifier).state = option,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (summary == null)
              Text(
                s.historyCounting,
                style: textTheme.bodySmall?.copyWith(color: c.textMuted),
              )
            else ...[
              Text(
                recap ?? summary.summary,
                style: textTheme.bodyMedium?.copyWith(
                  color: c.textSecondary,
                  height: 1.8,
                ),
              ),
              // The note belongs to the server's sentence. When this screen
              // wrote the line itself, no model was involved and saying so
              // would be a lie.
              if (summary.writtenByAi && recap == null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.historyAiNote,
                  style: textTheme.labelSmall?.copyWith(color: c.textMuted),
                ),
              ],
              if (summary.byFortune.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final tally in summary.byFortune.take(4))
                      _TallyPill(tally: tally),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
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
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxs),
      child: Material(
        color:
            selected ? c.goldWarm.withValues(alpha: 0.18) : Colors.transparent,
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
      ),
    );
  }
}

/// Counts in the reader's own digits — «۲» for Persian eyes, «2» otherwise.
String _digits(int n, String lang) => lang == 'fa' ? n.toPersianDigits : '$n';

class _TallyPill extends StatelessWidget {
  const _TallyPill({required this.tally});

  final FortuneTally tally;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final locale = Localizations.localeOf(context);
    // The tally arrives labelled in Persian: the summary endpoint answers
    // with `titleFa`, so under an English screen this chip used to read
    // «فال حافظ». The app already carries every fortune's name in all four
    // languages under the same id, and each Persian name there is identical
    // to the server's — so in Persian this renders the very string it always
    // did, and only en/ar/tr change. The server's label remains the fallback
    // for an id this build does not know yet.
    final known = FortuneRegistry.byId(tally.fortuneId);
    final name = known?.title.resolve(locale) ?? tally.title;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceElevated.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$name · ${_digits(tally.count, locale.languageCode)}',
        style: TextStyle(fontSize: 11, color: c.textMuted),
      ),
    );
  }
}
