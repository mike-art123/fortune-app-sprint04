import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../fortunes/domain/fortune_definition.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../reading/application/reading_submission_controller.dart';
import '../controllers/ritual_entry_controller.dart';
import '../widgets/whisper_field.dart';

/// Ritual Entry — a personal ritual, not a form. One still moon, one calm
/// line, a whisper, one clear action. Everything it renders comes from the
/// fortune's registry definition.
class RitualEntryPage extends ConsumerStatefulWidget {
  const RitualEntryPage({super.key, required this.fortuneId});
  final String fortuneId;

  @override
  ConsumerState<RitualEntryPage> createState() => _RitualEntryPageState();
}

class _RitualEntryPageState extends ConsumerState<RitualEntryPage> {
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  void _seal(FortuneDefinition fortune) {
    final input = ref
        .read(ritualEntryControllerProvider(fortune.id).notifier)
        .seal(
          fortune: fortune,
          primary: _primary.text,
          secondary: _secondary.text,
        );
    if (input != null) {
      // Real submission: Ritual → POST /readings → Reading screen.
      ref.read(readingSubmissionControllerProvider.notifier).submit(input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortune = FortuneRegistry.byId(widget.fortuneId);
    final s = context.strings;

    if (fortune == null || !fortune.isAvailable) {
      return FortuneScaffold(
        appBar: AppBar(),
        child: FortuneErrorState(
          message: s.routeNotFoundTitle,
          reassurance: s.routeNotFoundBody,
          retryLabel: s.actionBackToExplore,
          onRetry: () => context.go(AppRoutes.explorePath),
        ),
      );
    }

    final locale = Localizations.localeOf(context);
    final state = ref.watch(ritualEntryControllerProvider(fortune.id));
    final submission = ref.watch(readingSubmissionControllerProvider);

    // Navigate exactly once when the reading arrives; input stays preserved on
    // failure so nothing the user whispered is ever lost.
    ref.listen(readingSubmissionControllerProvider, (previous, next) {
      if (next is SubmissionSucceeded && mounted) {
        final reading = next.reading;
        ref.read(readingSubmissionControllerProvider.notifier).reset();
        context.push(AppRoutes.reading(reading.id), extra: reading);
      }
    });
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final pace = fortune.pace;

    return FortuneScaffold(
      appBar: AppBar(title: Text(fortune.title.resolve(locale))),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // The moon — the shared still anchor of every ritual.
          FortuneFadeIn(
            duration: pace.enter,
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      fortune.accent.withValues(alpha: 0.28),
                      fortune.accent.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fortune.accent.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // The single calm ritual line.
          FortuneFadeIn(
            duration: pace.enter + pace.step,
            child: Text(
              fortune.ritualLine.resolve(locale),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // The offering — rendered purely from the registry definition.
          FortuneFadeIn(
            duration: pace.enter + pace.step * 2,
            child: _buildOffering(fortune, locale),
          ),

          // Gentle guidance — neutral tone, no red, no blame.
          if (state.guidance != null) ...[
            const SizedBox(height: AppSpacing.md),
            FortuneFadeIn(
              duration: const Duration(milliseconds: 220),
              child: Text(
                state.guidance!.resolve(locale),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Quiet privacy reassurance for sensitive offerings.
          if (fortune.privacy != null) ...[
            Text(
              fortune.privacy!.resolve(locale),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Network failure — friendly Persian, retry stays one tap away.
          if (submission is SubmissionFailed) ...[
            Text(
              FailureMessageResolver.resolve(submission.failure),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          FortuneFadeIn(
            duration: pace.enter + pace.step * 3,
            child: FortuneButton(
              label: fortune.cta.resolve(locale),
              isLoading: submission is SubmissionInFlight,
              onPressed: submission is SubmissionInFlight
                  ? null
                  : () => _seal(fortune),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildOffering(FortuneDefinition fortune, Locale locale) {
    void soften() =>
        ref.read(ritualEntryControllerProvider(fortune.id).notifier).soften();

    switch (fortune.inputKind) {
      case FortuneInputKind.intention:
        return WhisperField(
          controller: _primary,
          accent: fortune.accent,
          placeholder: fortune.placeholder?.resolve(locale),
          maxLength: fortune.maxLength,
        );

      case FortuneInputKind.longText:
        return Listener(
          onPointerDown: (_) => soften(),
          child: WhisperField(
            controller: _primary,
            accent: fortune.accent,
            placeholder: fortune.placeholder?.resolve(locale),
            maxLength: fortune.maxLength,
            multiline: true,
            minLines: 4,
            centered: false,
          ),
        );

      case FortuneInputKind.twoNames:
        final c = context.fortuneColors;
        return Column(
          children: [
            WhisperField(
              controller: _primary,
              accent: fortune.accent,
              placeholder: fortune.placeholder?.resolve(locale),
              maxLength: fortune.maxLength,
            ),
            const SizedBox(height: AppSpacing.md),
            // The bond — a single quiet word, no ornament.
            Text(
              'و',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            WhisperField(
              controller: _secondary,
              accent: fortune.accent,
              placeholder: fortune.placeholderSecond?.resolve(locale),
              maxLength: fortune.maxLength,
            ),
          ],
        );

      case FortuneInputKind.photo:
        // Guarded above by `isAvailable`; unreachable in Sprint 01.
        return const SizedBox.shrink();
    }
  }
}
