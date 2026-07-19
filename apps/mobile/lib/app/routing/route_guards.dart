import '../app_startup_state.dart';

/// Foundation-phase guard: hold navigation at splash until startup completes
/// (doc 51 §12.3). Auth/entitlement guards are added in their own phases.
abstract final class RouteGuards {
  static String? redirect({
    required AppStartupState startup,
    required String location,
  }) {
    final atSplash = location.startsWith('/splash');
    if (startup is StartupInProgress || startup is StartupFailed) {
      return atSplash ? null : '/splash';
    }
    if (atSplash) return '/explore';
    return null;
  }
}
