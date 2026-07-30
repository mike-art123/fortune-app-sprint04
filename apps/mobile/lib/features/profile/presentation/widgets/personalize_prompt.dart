import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../ritual_entry/presentation/widgets/whisper_field.dart';
import '../../application/profile_controller.dart';
import '../../domain/user_profile.dart';
import 'month_pill.dart';

/// A gentle, optional personalization prompt (scope §16). It floats centered
/// over home — never a full-screen gate — asking for a name and a birth month
/// in one small card. Saving personalizes; «نمی‌خوام ثبت کنم» opts out for good
/// (server-side), so the card never returns on any device.
class PersonalizePrompt extends ConsumerStatefulWidget {
  const PersonalizePrompt({super.key});

  @override
  ConsumerState<PersonalizePrompt> createState() => _PersonalizePromptState();
}

class _PersonalizePromptState extends ConsumerState<PersonalizePrompt> {
  final _name = TextEditingController();
  String? _month;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ready => _name.text.trim().isNotEmpty && _month != null;

  Future<void> _save() async {
    if (_saving || !_ready) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .completeOnboarding(displayName: _name.text, birthMonth: _month!);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = FailureMessageResolver.resolve(failure);
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(personalizationOptOut: true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final s = context.strings;
    return GoldBorderContainer(
      // A touch taller than the default card: the prompt breathes, and the
      // language row above the title gets its own quiet space.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LanguagePill(),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Language',
                style: TextStyle(color: c.textMuted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.personalizeTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          WhisperField(
            controller: _name,
            accent: c.goldWarm,
            placeholder: s.personalizeNameHint,
            maxLength: 40,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.personalizeMonthQuestion,
            style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final m in kBirthMonths)
                MonthPill(
                  label: m.fa,
                  selected: _month == m.value,
                  onTap: () => setState(() => _month = m.value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.personalizeNote,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FortuneButton(
            label: _saving ? s.personalizeSaving : s.personalizeGo,
            isLoading: _saving,
            onPressed: _ready && !_saving ? _save : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          FortuneButton(
            label: s.personalizeSkip,
            variant: FortuneButtonVariant.text,
            onPressed: _saving ? null : _skip,
          ),
        ],
      ),
    );
  }
}
