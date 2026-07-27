import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/motion/ambient_motion.dart';
import 'localization/app_strings.dart';
import 'localization/locale_controller.dart';
import 'localization/supported_locales.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Root widget. Locale drives text direction, so Persian gives RTL natively.
class FortuneApp extends ConsumerWidget {
  const FortuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // One ambient clock above every screen: the fortune cards animate
      // from it, and it alone honours reduced motion and lifecycle
      // pauses.
      builder: (context, child) {
        return AmbientMotion(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
      locale: locale,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
