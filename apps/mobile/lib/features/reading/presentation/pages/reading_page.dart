import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_divider.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../history/application/history_controller.dart';
import '../../domain/reading.dart';

/// The reading — presented as a quiet page written for one person.
/// Arriving from the ritual, the entity is already in hand; arriving cold
/// (deep link, history refresh) it is fetched by id. Either way, the page
/// only ever renders a reading that truly exists.
class ReadingPage extends ConsumerWidget {
  const ReadingPage({super.key, required this.readingId, this.reading});

  final String readingId;

  /// Passed by the submission flow / history tap; null on cold deep links.
  final Reading? reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final c = context.fortuneColors;

    final current = reading;
    if (current == null) {
      // Cold deep link — fetch by id. Loading is quiet; failure is honest.
      final fetched = ref.watch(readingByIdProvider(readingId));
      return fetched.when(
        loading: () => FortuneScaffold(
          appBar: AppBar(),
          child: const Center(child: FortuneLoading()),
        ),
        error: (error, _) => FortuneScaffold(
          appBar: AppBar(),
          child: FortuneErrorState(
            message: error is AppFailure
                ? FailureMessageResolver.resolve(error)
                : s.readingUnavailableTitle,
            reassurance: s.readingUnavailableBody,
            retryLabel: s.actionBackToExplore,
            onRetry: () => context.go(AppRoutes.explorePath),
          ),
        ),
        data: (loaded) => _ReadingView(reading: loaded),
      );
    }

    return _ReadingView(reading: current);
  }
}

class _ReadingView extends StatelessWidget {
  const _ReadingView({required this.reading});

  final Reading reading;

  String _formatDate(BuildContext context, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final formatted = '$y/$m/$d';
    return Localizations.localeOf(context).languageCode == 'fa'
        ? formatted.toPersianDigits
        : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.fortuneColors;
    final current = reading;

    final locale = Localizations.localeOf(context);
    final fortune = FortuneRegistry.byId(current.fortuneId);
    final accent = fortune?.accent ?? c.accentSecondary;
    final textTheme = Theme.of(context).textTheme;

    return FortuneScaffold(
      appBar: AppBar(
        title: Text(fortune?.title.resolve(locale) ?? s.readingTitle),
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // A thin accent line — the illumination mark, never a gold fill.
          FortuneFadeIn(
            child: Center(
              child: Container(
                width: 56,
                height: 2,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          FortuneFadeIn(
            duration: const Duration(milliseconds: 420),
            child: Text(
              current.title,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FortuneFadeIn(
            duration: const Duration(milliseconds: 520),
            child: Text(
              _formatDate(context, current.createdAt),
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: c.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Long-form reading body: generous line height, reading-first.
          FortuneFadeIn(
            duration: const Duration(milliseconds: 640),
            child: Text(
              current.text,
              style: textTheme.bodyLarge?.copyWith(height: 2.0),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          const FortuneDivider(),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: FortuneButton(
                  label: s.actionSave,
                  variant: FortuneButtonVariant.secondary,
                  // Every reading is already persisted server-side; "save" is
                  // the emotional confirmation, not a second write.
                  onPressed: () => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(content: Text(s.savedToHistory)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FortuneButton(
                  label: s.actionShare,
                  variant: FortuneButtonVariant.secondary,
                  onPressed: () => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(content: Text(s.comingSoonDetail)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FortuneButton(
            label: s.actionBackToExplore,
            variant: FortuneButtonVariant.text,
            onPressed: () => context.go(AppRoutes.explorePath),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
