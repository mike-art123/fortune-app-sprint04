import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/providers/shared_providers.dart';

/// The app footer: the four public pages, the version, and the copyright
/// line — one calm block, shared by the legal pages and the terms tab.
class LegalFooter extends ConsumerWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    final config = ref.watch(appConfigProvider);
    const links = <(String, String)>[
      ('درباره', AppRoutes.aboutPath),
      ('حریم خصوصی', AppRoutes.privacyPath),
      ('قوانین', AppRoutes.termsPath),
      ('تماس', AppRoutes.contactPath),
    ];
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final link in links)
              InkWell(
                onTap: () => context.push(link.$2),
                child: Text(
                  link.$1,
                  style: TextStyle(
                    color: c.goldWarm,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'نسخهٔ ${config.appVersion}+${config.buildNumber}',
          style: TextStyle(color: c.textMuted, fontSize: 11.5),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '© بخت‌نگار ${DateTime.now().year} — همهٔ حقوق محفوظ است.',
          style: TextStyle(color: c.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }
}
