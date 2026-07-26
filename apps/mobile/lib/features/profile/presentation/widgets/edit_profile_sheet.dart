import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../ritual_entry/presentation/widgets/whisper_field.dart';
import '../../application/profile_controller.dart';
import '../../domain/user_profile.dart';
import 'month_pill.dart';

/// Opens the profile editor (scope §16): the name and birth month can be
/// changed after onboarding, and the backend stays the source of truth.
Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const EditProfileSheet(),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _name;
  String? _month;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    _name = TextEditingController(text: profile?.displayName ?? '');
    _month = profile?.birthMonth;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_saving || !_nameValid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure =
        await ref.read(profileControllerProvider.notifier).updateProfile(
              displayName: _name.text,
              birthMonth: _month,
            );
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

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppPalette.nightPanel,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نام و ماه تولد',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            WhisperField(
              controller: _name,
              accent: c.goldWarm,
              placeholder: 'نامت، یا نامی که دوستش داری',
              maxLength: 40,
            ),
            const SizedBox(height: AppSpacing.lg),
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
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FortuneButton(
              label: _saving ? 'در حال ذخیره…' : 'ذخیره',
              isLoading: _saving,
              onPressed: !_nameValid || _saving ? null : () => _save(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FortuneButton(
              label: 'انصراف',
              variant: FortuneButtonVariant.text,
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
