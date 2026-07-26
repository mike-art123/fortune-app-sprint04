import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';

/// One place that answers «چطور برگردیم؟» for the whole app, so the app-bar
/// back button, the Telegram BackButton and the browser/system back all behave
/// identically: pop when there is somewhere to return to, otherwise land on the
/// safe home base («فال‌ها»). A route is therefore never a dead end.
abstract final class AppBack {
  /// Safe destination when there is no previous route to return to.
  static const fallbackPath = AppRoutes.allFortunesPath;

  /// Bottom-navigation destinations, reached by replacing the stack. When one
  /// of these is the current stack root there is nothing to pop to, so no back
  /// affordance is shown — «back» there would only loop.
  static const _stackRoots = <String>[
    AppRoutes.splashPath,
    AppRoutes.homePath,
    AppRoutes.allFortunesPath,
    AppRoutes.historyPath,
    AppRoutes.profilePath,
  ];

  /// Go back from a widget that has a [BuildContext].
  static void goBack(BuildContext context) => goBackWith(GoRouter.of(context));

  /// Go back from a caller without a context (route observers, the Telegram
  /// back handler). Pops the current route, or falls back to [fallbackPath].
  static void goBackWith(GoRouter router) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallbackPath);
    }
  }

  /// Whether a back affordance belongs on [location]. A poppable route always
  /// offers one; a non-poppable route offers one too (falling back to Explore)
  /// unless it is a stack root, where back would only loop.
  static bool showBack({required String location, required bool canPop}) {
    if (canPop) return true;
    return !_stackRoots.contains(location);
  }
}
