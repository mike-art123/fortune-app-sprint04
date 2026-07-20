import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/profile_placeholder_page.dart';
import '../../features/reading/domain/reading.dart';
import '../../features/reading/presentation/pages/reading_page.dart';
import '../../features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import '../../features/splash/presentation/controllers/startup_controller.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../shared/providers/shared_providers.dart';
import '../app_startup_state.dart';
import '../localization/app_strings.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_observer.dart';

/// Central router (doc 51 §12). Deep-link ready: parameters are validated so a
/// malformed link can never crash the app or reach the backend.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: false,
    observers: [AnalyticsRouteObserver(ref.watch(analyticsServiceProvider))],
    redirect: (context, state) {
      final startup =
          ref.read(startupControllerProvider).valueOrNull ??
          const StartupInProgress();
      return RouteGuards.redirect(
        startup: startup,
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
        path: AppRoutes.explorePath,
        name: AppRoutes.exploreName,
        builder: (_, __) => const ExplorePage(),
      ),
      GoRoute(
        path: AppRoutes.ritualPath,
        name: AppRoutes.ritualName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['fortuneId'];
          final child = RouteParams.isValidId(id)
              ? RitualEntryPage(fortuneId: id!)
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
                  reading: state.extra is Reading
                      ? state.extra as Reading
                      : null,
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
        path: AppRoutes.walletPath,
        name: AppRoutes.walletName,
        builder: (_, __) => const WalletPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePath,
        name: AppRoutes.profileName,
        builder: (_, __) => const ProfilePlaceholderPage(),
      ),
    ],
    errorBuilder: (_, __) => const _NotFoundPage(),
  );
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
                  onPressed: () => context.go(AppRoutes.explorePath),
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
