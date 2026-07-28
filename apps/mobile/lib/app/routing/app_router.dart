import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/fortunes/presentation/pages/all_fortunes_page.dart';
import '../../features/fortunes/presentation/pages/coffee_guide_page.dart';
import '../../features/fortunes/presentation/pages/elements_guide_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/intentions/presentation/pages/intentions_page.dart';
import '../../features/saved/presentation/pages/saved_page.dart';
import '../../features/terms/presentation/pages/terms_page.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_placeholder_page.dart';
import '../../features/reading/domain/reading.dart';
import '../../features/reading/presentation/pages/reading_page.dart';
import '../../features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/controllers/startup_controller.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/providers/shared_providers.dart';
import '../app_startup_state.dart';
import '../localization/app_strings.dart';
import '../navigation/telegram_back_observer.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_observer.dart';

/// Central router (doc 51 §12). Deep-link ready: parameters are validated so a
/// malformed link can never crash the app or reach the backend.
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter's redirect does not observe Riverpod. Without this bridge, a
  // change in startup state (loading -> ready) never re-runs the guard, so the
  // app stays on the splash ("Preparing…") forever even once startup has
  // completed. A Listenable that ticks on every startup change forces the guard
  // to re-evaluate and navigate to /explore the moment startup is ready.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AppStartupState>>(
    startupControllerProvider,
    (_, __) => refresh.value++,
  );
  // The onboarding gate (scope §16) re-evaluates whenever the profile loads
  // or completes — same bridge pattern as startup above.
  ref.listen<AsyncValue<UserProfile?>>(
    profileControllerProvider,
    (_, __) => refresh.value++,
  );

  // Drives the Telegram BackButton from the route stack (bound after the router
  // exists). A no-op off Telegram; disposed with the provider.
  final telegramBack = TelegramBackObserver(ref.watch(telegramBridgeProvider));
  ref.onDispose(telegramBack.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    observers: [
      AnalyticsRouteObserver(ref.watch(analyticsServiceProvider)),
      telegramBack,
    ],
    redirect: (context, state) {
      final startup = ref.read(startupControllerProvider).valueOrNull ??
          const StartupInProgress();
      final profile = ref.read(profileControllerProvider);
      // Unknown while loading; a failed fetch must not trap the app on
      // splash forever, so a hard failure counts as "no gate".
      final onboardingCompleted =
          profile.hasError ? true : profile.valueOrNull?.onboardingCompleted;
      return RouteGuards.redirect(
        startup: startup,
        onboardingCompleted:
            startup is StartupReady ? onboardingCompleted : null,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        // Cross-fade + a whisper of scale from the splash into Home. Both
        // screens share the same dark canvas — no white/black flash.
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const HomePage(),
          transitionDuration: const Duration(milliseconds: 420),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.allFortunesPath,
        name: AppRoutes.allFortunesName,
        builder: (_, __) => const AllFortunesPage(),
      ),
      GoRoute(
        path: AppRoutes.coffeePath,
        name: AppRoutes.coffeeName,
        builder: (_, __) => const CoffeeGuidePage(),
      ),
      GoRoute(
        path: AppRoutes.elementsPath,
        name: AppRoutes.elementsName,
        builder: (_, __) => const ElementsGuidePage(),
      ),
      GoRoute(
        path: AppRoutes.explorePath,
        name: AppRoutes.exploreName,
        // Legacy Explore is deprecated and must never show in production:
        // always redirect to the real «فال‌ها» grid. The builder is kept only
        // so the widget/import stays referenced.
        redirect: (context, state) => AppRoutes.allFortunesPath,
        builder: (_, __) => const ExplorePage(),
      ),
      GoRoute(
        path: AppRoutes.ritualPath,
        name: AppRoutes.ritualName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['fortuneId'];
          // Keyed by fortune so moving between two rituals never reuses the
          // previous ritual's State — a whisper typed for one fortune must
          // not appear inside another (found in live phase-5 verification).
          final child = RouteParams.isValidId(id)
              ? RitualEntryPage(key: ValueKey('ritual-$id'), fortuneId: id!)
              : const _NotFoundPage();
          return _fadePage(state, child);
        },
      ),
      GoRoute(
        path: AppRoutes.readingPath,
        name: AppRoutes.readingName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['readingId'];
          final child = RouteParams.isValidId(id)
              ? ReadingPage(
                  readingId: id!,
                  reading:
                      state.extra is Reading ? state.extra as Reading : null,
                )
              : const _NotFoundPage();
          return _fadePage(state, child);
        },
      ),
      GoRoute(
        path: AppRoutes.historyPath,
        name: AppRoutes.historyName,
        builder: (_, __) => const HistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.termsPath,
        name: AppRoutes.termsName,
        builder: (_, __) => const TermsPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePath,
        name: AppRoutes.profileName,
        builder: (_, __) => const ProfilePlaceholderPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        name: AppRoutes.settingsName,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.intentionsPath,
        name: AppRoutes.intentionsName,
        builder: (_, __) => const IntentionsPage(),
      ),
      GoRoute(
        path: AppRoutes.savedPath,
        name: AppRoutes.savedName,
        builder: (_, __) => const SavedPage(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboardingName,
        builder: (_, state) =>
            OnboardingPage(next: state.uri.queryParameters['next']),
      ),
    ],
    errorBuilder: (_, __) => const _NotFoundPage(),
  );
  telegramBack.bind(router);
  return router;
});

/// Entering the ritual/reading space is a passage, not a push — a quiet
/// cross-fade honours that (Motion: calm over spectacle).
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Branded recovery page — never a raw 404 (doc 51 §12.4).
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.routeNotFoundTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  s.routeNotFoundBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go(AppRoutes.allFortunesPath),
                  child: Text(s.actionBackToExplore),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
