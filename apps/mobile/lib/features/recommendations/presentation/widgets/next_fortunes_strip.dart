import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/fortune_destinations.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/next_fortunes_provider.dart';
import '../../domain/next_fortunes.dart';

/// «بعد از این» — at most three quiet cards under a finished reading
/// (scope §5).
///
/// Each one says why it is there. Nothing appears while the answer is still
/// being worked out, and nothing appears at all when personalization is off —
/// the reading simply ends, as it always did.
class NextFortunesStrip extends ConsumerWidget {
  const NextFortunesStrip({required this.fortuneId, super.key});

  final String fortuneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(nextFortunesProvider(fortuneId));
    final list = suggestions.valueOrNull ?? const <NextFortune>[];
    if (list.isEmpty) return const SizedBox.shrink();

    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'بعد از این',
          style: textTheme.titleMedium?.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final next in list)
          _NextCard(
            next: next,
            onTap: () {
              // The suggestion carries an id, never a path: it opens through
              // the same map every card and every search result uses.
              final path = FortuneDestinations.pathFor(next.fortuneId);
              if (path != null) context.push(path);
            },
          ),
      ],
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next, required this.onTap});

  final NextFortune next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Material(
        color: c.surfaceElevated.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        next.reason,
                        style: textTheme.bodySmall?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, size: 20, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
