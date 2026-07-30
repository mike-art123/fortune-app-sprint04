import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/locale_controller.dart';
import '../../app/localization/supported_locales.dart';
import '../../design_system/foundations/app_spacing.dart';
import '../../design_system/theme/fortune_theme_extension.dart';

/// Every supported language, written in its own script — a reader should
/// recognise their language even when the rest of the app is foreign.
String nativeLanguageName(String code) {
  return switch (code) {
    'en' => 'English',
    'ar' => 'العربية',
    'tr' => 'Türkçe',
    _ => 'فارسی',
  };
}

/// The compact trigger: the current language in its own script, tappable.
/// Reads the locale from the tree (not a provider), so it renders anywhere;
/// selection happens inside the picker sheet through its own ref.
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final code = Localizations.localeOf(context).languageCode;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLanguagePicker(context),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.goldWarm.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nativeLanguageName(code),
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.expand_more_rounded, size: 16, color: c.goldWarm),
          ],
        ),
      ),
    );
  }
}

/// The four languages, current one marked; choosing switches the whole app
/// immediately and persists the preference.
Future<void> showLanguagePicker(BuildContext context) {
  final current = Localizations.localeOf(context).languageCode;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _LanguageSheet(current: current),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    return SafeArea(
      child: Container(
        margin: const EdgeInsetsDirectional.all(AppSpacing.sm),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'زبان · Language',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final locale in SupportedLocales.all)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref.read(localeControllerProvider.notifier).select(locale);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nativeLanguageName(locale.languageCode),
                          style: TextStyle(
                            color: locale.languageCode == current
                                ? c.goldWarm
                                : c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (locale.languageCode == current)
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: c.goldWarm,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
