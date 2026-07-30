import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/fortune_focus.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../core/config/android_bridges_switch.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../history/application/history_controller.dart';
import '../../../saved/application/saved_controller.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../recommendations/presentation/widgets/next_fortunes_strip.dart';
import '../../../reflections/presentation/widgets/reflection_card.dart';
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

    final current = reading;
    if (current == null) {
      // Cold deep link — fetch by id. Loading is quiet; failure is honest.
      final fetched = ref.watch(readingByIdProvider(readingId));
      return fetched.when(
        loading: () => const FortuneScaffold(
          appBar: FortuneAppBar(),
          child: Center(child: FortuneLoading()),
        ),
        error: (error, _) => FortuneScaffold(
          appBar: const FortuneAppBar(),
          child: FortuneErrorState(
            message: error is AppFailure
                ? FailureMessageResolver.resolve(error)
                : s.readingUnavailableTitle,
            reassurance: s.readingUnavailableBody,
            retryLabel: s.actionBackToExplore,
            onRetry: () => context.go(AppRoutes.allFortunesPath),
          ),
        ),
        data: (loaded) => _ReadingView(reading: loaded),
      );
    }

    return _ReadingView(reading: current);
  }
}

class _ReadingView extends ConsumerWidget {
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

  /// Real share: the reading is copied for pasting anywhere; inside Telegram
  /// the Telegram share dialog opens, and on the Play build the Android share
  /// sheet does (the bridge routes the same link either way). Privacy
  /// (scope §16): the person's name is stripped from the shared text — what
  /// leaves the app is impersonal by default.
  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final bridge = ref.read(telegramBridgeProvider);
    final name = ref.read(profileControllerProvider).valueOrNull?.displayName;
    final body = stripLeadingName(reading.text, name);
    final brand = context.strings.shareBrandLine;
    final text = '${reading.title}\n\n$body\n\n$brand';

    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      copied = false; // never a silent failure — the snackbar tells the truth
    }
    if (bridge.isAvailable || kAndroidBridgesEnabled) {
      final url = Uri(
        scheme: 'https',
        host: 't.me',
        path: 'share/url',
        queryParameters: {'url': 'https://t.me/bakhtnegarbot', 'text': text},
      ).toString();
      await bridge.openTelegramLink(url);
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          copied ? context.strings.shareCopied : context.strings.shareFailed,
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref, String id) async {
    final result = await ref.read(savedRepositoryProvider).save(id);
    if (!context.mounted) return;
    final s = context.strings;
    final message = result.fold(
      onSuccess: (_) => s.savedToast,
      onFailure: (_) => s.savedError,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final c = context.fortuneColors;
    final current = reading;

    final locale = Localizations.localeOf(context);
    final fortune = FortuneRegistry.byId(current.fortuneId);
    final accent = fortune?.accent ?? c.goldWarm;
    final textTheme = Theme.of(context).textTheme;

    return FortuneScaffold(
      appBar: FortuneAppBar(
        title: Text(fortune?.title.resolve(locale) ?? s.readingTitle),
        actions: [
          IconButton(
            onPressed: () => _save(context, ref, current.id),
            tooltip: s.savedSaveTooltip,
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Hero illustration in the fortune's own light: its focal crop and a
          // soft aura in its accent, so the result page carries the same
          // identity as the ritual that led here (interior phase 4).
          FortuneFadeIn(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.26),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Image.asset(
                  'assets/fortunes/${current.fortuneId}.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: fortuneFocalAlignment(current.fortuneId),
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
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
          const SizedBox(height: AppSpacing.xs),

          // A quiet ornament in the fortune's accent between date and body.
          FortuneFadeIn(
            duration: const Duration(milliseconds: 560),
            child: _AccentDivider(accent: accent),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Long-form reading body in a premium gold-edged card.
          FortuneFadeIn(
            duration: const Duration(milliseconds: 640),
            child: GoldBorderContainer(
              child: Text(
                current.text,
                style: textTheme.bodyLarge?.copyWith(height: 2.0),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: FortuneButton(
                  label: s.actionSave,
                  variant: FortuneButtonVariant.secondary,
                  // Every reading is already persisted server-side; "save" is
                  // the emotional confirmation, not a second write.
                  onPressed: () {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.clearSnackBars();
                    messenger?.showSnackBar(
                      SnackBar(content: Text(s.savedToHistory)),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FortuneButton(
                  label: s.actionShare,
                  variant: FortuneButtonVariant.secondary,
                  onPressed: () => _share(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FortuneButton(
            label: s.actionBackToExplore,
            variant: FortuneButtonVariant.text,
            onPressed: () => context.go(AppRoutes.allFortunesPath),
          ),
          // A private note for whoever wrote it, and nobody else (scope §8).
          ReflectionCard(readingId: current.id),
          // Where to go next, drawn from this reader's own history (scope §5).
          NextFortunesStrip(fortuneId: current.fortuneId),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// A hairline that breathes in the fortune's accent: fading lines meeting a
/// small rotated diamond — an ornament, never a border.
class _AccentDivider extends StatelessWidget {
  const _AccentDivider({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget line(AlignmentGeometry begin, AlignmentGeometry end) {
      return Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                accent.withValues(alpha: 0),
                accent.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        line(AlignmentDirectional.centerStart, AlignmentDirectional.centerEnd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 7, height: 7, color: accent),
          ),
        ),
        line(AlignmentDirectional.centerEnd, AlignmentDirectional.centerStart),
      ],
    );
  }
}
