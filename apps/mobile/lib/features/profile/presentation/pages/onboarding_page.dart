import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/navigation/app_back.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../ritual_entry/presentation/widgets/whisper_field.dart';
import '../../application/profile_controller.dart';
import '../../domain/user_profile.dart';
import '../widgets/month_pill.dart';

/// First-run onboarding (scope §16) — a quiet ritual, not a form: one whisper
/// for the name, one ring of months, one gentle confirmation. Shown exactly
/// once per account; the backend decides, so no device or cache can bring it
/// back after completion.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.next});

  /// Where to continue after completion (deep links land back on target).
  final String? next;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _name = TextEditingController();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // The continue button follows validity while the person types.
    _name.addListener(() => setState(() {}));
  }

  String? _month;
  bool _saving = false;
  bool _leaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;

  Future<void> _finish() async {
    if (_saving || !_nameValid || _month == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .completeOnboarding(displayName: _name.text, birthMonth: _month!);
    if (!mounted) return;
    if (failure != null) {
      // The typed name and chosen month stay exactly as they were.
      setState(() {
        _saving = false;
        _error = FailureMessageResolver.resolve(failure);
      });
      return;
    }
    setState(() {
      _saving = false;
      _step = 2;
    });
  }

  void _continueToApp() {
    final target = widget.next;
    context.go(
      target != null && target.startsWith('/') ? target : AppBack.fallbackPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final name = _name.text.trim();

    // An already-onboarded visitor (deep link, second tab) is never asked
    // again — the ritual happened once. The welcome step is the single moment
    // a completed profile is allowed to linger here.
    final completed =
        ref.watch(profileControllerProvider).valueOrNull?.onboardingCompleted ??
            false;
    if (completed && _step != 2 && !_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _continueToApp();
      });
    }

    return FortuneScaffold(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          FortuneFadeIn(
            child: Text(
              switch (_step) {
                0 => context.strings.onboardingNameQuestion,
                1 => context.strings.onboardingMonthQuestion,
                _ => context.strings.onboardingWelcome(name),
              },
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_step == 0)
            WhisperField(
              controller: _name,
              accent: c.goldWarm,
              placeholder: context.strings.personalizeNameHint,
              maxLength: 40,
            ),
          if (_step == 1)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in kBirthMonths)
                  MonthPill(
                    label: monthLabel(
                      m,
                      Localizations.localeOf(context).languageCode,
                    ),
                    selected: _month == m.value,
                    onTap: () => setState(() => _month = m.value),
                  ),
              ],
            ),
          if (_step == 2)
            Text(
              context.strings.onboardingPersonalNote,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: c.textSecondary),
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_step == 0)
            FortuneButton(
              label: context.strings.actionContinue,
              onPressed: _nameValid ? () => setState(() => _step = 1) : null,
            ),
          if (_step == 1) ...[
            FortuneButton(
              label: _saving
                  ? context.strings.personalizeSaving
                  : context.strings.actionContinue,
              isLoading: _saving,
              onPressed: _month == null || _saving ? null : () => _finish(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FortuneButton(
              label: context.strings.actionBack,
              variant: FortuneButtonVariant.text,
              onPressed: _saving ? null : () => setState(() => _step = 0),
            ),
          ],
          if (_step == 2)
            FortuneButton(
              label: context.strings.personalizeGo,
              onPressed: _continueToApp,
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
