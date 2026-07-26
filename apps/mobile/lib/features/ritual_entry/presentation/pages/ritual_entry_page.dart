import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../access/application/access_flow_controller.dart';
import '../../../access/presentation/widgets/access_sheet.dart';
import '../../../fortunes/domain/fal_input.dart';
import '../../../fortunes/domain/fortune_definition.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../reading/application/reading_submission_controller.dart';
import '../controllers/ritual_entry_controller.dart';
import '../widgets/offering_strip.dart';
import '../widgets/paired_names_field.dart';
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

  /// The sealed offering, preserved across the access sheet, the ad and the
  /// VIP purchase flow — the user never types anything twice.
  FalInput? _pendingInput;

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  void _seal(FortuneDefinition fortune) {
    final input =
        ref.read(ritualEntryControllerProvider(fortune.id).notifier).seal(
              fortune: fortune,
              primary: _primary.text,
              secondary: _secondary.text,
            );
    if (input != null) {
      // Access first (VIP → free daily → sheet); submission follows access.
      _pendingInput = input;
      ref.read(accessFlowControllerProvider(fortune.id).notifier).begin();
    }
  }

  AccessFlowController _access(FortuneDefinition fortune) {
    return ref.read(accessFlowControllerProvider(fortune.id).notifier);
  }

  void _submitPending(FortuneDefinition fortune, String? adEntitlementId) {
    final input = _pendingInput;
    if (input == null) return;
    _access(fortune).reset();
    ref
        .read(readingSubmissionControllerProvider.notifier)
        .submit(input, adEntitlementId: adEntitlementId);
  }

  Future<void> _onAccessChanged(
    FortuneDefinition fortune,
    AccessFlowState next,
  ) async {
    switch (next) {
      case AccessProceed(:final adEntitlementId):
        _submitPending(fortune, adEntitlementId);
      case AccessSheet():
        final choice = await showAccessSheet(
          context,
          fortuneName: fortune.title.resolve(Localizations.localeOf(context)),
        );
        if (!mounted) return;
        if (choice == 'ad') {
          await _access(fortune).watchAd();
        } else if (choice == 'vip') {
          await _goVipAndRecheck(fortune);
        } else {
          _access(fortune).reset();
        }
      case AccessLimitReached():
        final goVip = await showAdLimitDialog(context);
        if (!mounted) return;
        if (goVip) {
          await _goVipAndRecheck(fortune);
        } else {
          _access(fortune).reset();
        }
      case AccessAdsExhausted():
        final action = await showAdsExhaustedDialog(context);
        if (!mounted) return;
        if (action == 'retry') {
          await _access(fortune).watchAd();
        } else if (action == 'vip') {
          await _goVipAndRecheck(fortune);
        } else {
          _access(fortune).reset();
        }
      case AccessError(:final failure):
        _access(fortune).reset();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(FailureMessageResolver.resolve(failure))),
        );
      case AccessIdle():
      case AccessChecking():
      case AccessPreparingAd():
        break;
    }
  }

  /// VIP purchase keeps the pending offering; on return, re-check access and
  /// continue automatically when the subscription now covers it.
  Future<void> _goVipAndRecheck(FortuneDefinition fortune) async {
    await context.push(AppRoutes.vipPath);
    if (!mounted || _pendingInput == null) return;
    await _access(fortune).begin();
  }

  @override
  Widget build(BuildContext context) {
    final fortune = FortuneRegistry.byId(widget.fortuneId);
    final s = context.strings;

    if (fortune == null || !fortune.isAvailable) {
      return FortuneScaffold(
        appBar: const FortuneAppBar(),
        child: FortuneErrorState(
          message: s.routeNotFoundTitle,
          reassurance: s.routeNotFoundBody,
          retryLabel: s.actionBackToExplore,
          onRetry: () => context.go(AppRoutes.allFortunesPath),
        ),
      );
    }

    final locale = Localizations.localeOf(context);
    final state = ref.watch(ritualEntryControllerProvider(fortune.id));
    final submission = ref.watch(readingSubmissionControllerProvider);
    final access = ref.watch(accessFlowControllerProvider(fortune.id));

    // Navigate exactly once when the reading arrives; input stays preserved on
    // failure so nothing the user whispered is ever lost.
    ref.listen(readingSubmissionControllerProvider, (previous, next) {
      if (next is SubmissionSucceeded && mounted) {
        final reading = next.reading;
        ref.read(readingSubmissionControllerProvider.notifier).reset();
        context.push(AppRoutes.reading(reading.id), extra: reading);
      }
    });

    // Access decisions (sheet / limit / exhausted / proceed) arrive as state;
    // the page reacts with the matching surface while the offering is kept.
    ref.listen(accessFlowControllerProvider(fortune.id), (previous, next) {
      if (previous != next && mounted) {
        unawaited(_onAccessChanged(fortune, next));
      }
    });
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final pace = fortune.pace;

    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(fortune.title.resolve(locale))),
      scrollable: true,
      background: _RitualBackdrop(
        fortuneId: fortune.id,
        accent: fortune.accent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // The still anchor: a moon at rest, the glowing orb while sealing.
          FortuneFadeIn(
            duration: pace.enter,
            child: Center(
              child: _anchor(submission is SubmissionInFlight, fortune),
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

          // Bespoke offering elements (phase 5): a month, a colour or a short
          // intent that seeds the whisper above — registry-driven, and the
          // person can always keep editing the seeded text by hand.
          if (fortune.offering != FortuneOffering.none) ...[
            const SizedBox(height: AppSpacing.lg),
            FortuneFadeIn(
              duration: pace.enter + pace.step * 2,
              child: OfferingStrip(
                offering: fortune.offering,
                accent: fortune.accent,
                chips: fortune.offeringChips,
                onSeed: _seedIntention,
              ),
            ),
          ],

          // Dream only: golden theme emblems that seed the whisper with a
          // starting word — inspiration, never a dead ornament.
          if (fortune.id == 'dream') ...[
            const SizedBox(height: AppSpacing.md),
            _DreamCategories(onPick: _appendTopic),
          ],

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
              label: access is AccessPreparingAd
                  ? 'در حال آماده‌سازی تبلیغ...'
                  : fortune.cta.resolve(locale),
              isLoading: submission is SubmissionInFlight ||
                  access is AccessChecking ||
                  access is AccessPreparingAd,
              onPressed: submission is SubmissionInFlight ||
                      access is AccessChecking ||
                      access is AccessPreparingAd
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
        return PairedNamesField(
          first: _primary,
          second: _secondary,
          accent: fortune.accent,
          firstPlaceholder: fortune.placeholder?.resolve(locale),
          secondPlaceholder: fortune.placeholderSecond?.resolve(locale),
          maxLength: fortune.maxLength,
        );

      case FortuneInputKind.photo:
        // Guarded above by `isAvailable`; unreachable in Sprint 01.
        return const SizedBox.shrink();
    }
  }

  // Seed the dream whisper with a chosen theme word, keeping the caret at the
  // end so the person simply keeps writing.
  void _appendTopic(String label) {
    final existing = _primary.text.trim();
    final next = existing.isEmpty ? label : '$existing $label';
    _primary.text = next;
    _primary.selection = TextSelection.collapsed(offset: next.length);
  }

  // Seed the whisper with a bespoke choice (a month, a colour, a short intent),
  // caret at the end so the person can keep editing. Any guidance is softened.
  void _seedIntention(String value) {
    _primary.text = value;
    _primary.selection = TextSelection.collapsed(offset: value.length);
    ref.read(ritualEntryControllerProvider(widget.fortuneId).notifier).soften();
  }

  // At rest the moon holds the gaze; while the reading is sealing, the golden
  // orb takes its place. Both fall back to the moon if the art can't load.
  Widget _anchor(bool loading, FortuneDefinition fortune) {
    if (loading) {
      return Image.asset(
        'assets/misc/loading_orb.jpg',
        width: 72,
        height: 72,
        errorBuilder: (context, error, stack) => _moon(fortune),
      );
    }
    return _moon(fortune);
  }

  Widget _moon(FortuneDefinition fortune) {
    return Container(
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
    );
  }
}

/// Per-fortune themed backdrop: the fortune's own artwork, faded behind a dark
/// navy scrim (so the calm text stays readable) with a soft accent glow rising
/// from the bottom. Falls back to the shared candlelit image, then to black.
class _RitualBackdrop extends StatelessWidget {
  const _RitualBackdrop({required this.fortuneId, required this.accent});

  final String fortuneId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/fortunes/$fortuneId.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Image.asset(
              'assets/bg/bg_ritual.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: Colors.black),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x9E05070F), Color(0xD605070F)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, accent.withValues(alpha: 0.16)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A horizontal band of golden dream-theme emblems. Tapping one seeds the
/// whisper with that theme word via [onPick] — decorative and useful at once.
class _DreamCategories extends StatelessWidget {
  const _DreamCategories({required this.onPick});

  final void Function(String label) onPick;

  static const _items = [
    ('dc_nature', 'طبیعت'),
    ('dc_objects', 'اشیا'),
    ('dc_animals', 'حیوانات'),
    ('dc_people', 'افراد'),
    ('dc_emotions', 'احساسات'),
    ('dc_events', 'حوادث'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => onPick(item.$2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/dream/${item.$1}.jpg',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        Icon(Icons.auto_awesome, color: c.goldWarm, size: 30),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(item.$2, style: textTheme.labelSmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
