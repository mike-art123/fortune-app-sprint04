import '../app_startup_state.dart';

/// Navigation gates (doc 51 §12.3 + scope §16).
///
/// Order of truth: startup first (auth/bootstrap), then the profile. While
/// either is still unknown the app holds on splash, so the landing screen
/// never flashes a guest greeting before the real profile arrives. Once both
/// are known the app goes home — onboarding is NOT a gate: a visitor who has
/// not personalized is invited to, from a gentle card on home
/// (PersonalizePrompt), and is never trapped on a full-screen step.
abstract final class RouteGuards {
  static String? redirect({
    required AppStartupState startup,
    required bool? onboardingCompleted,
    required String location,
  }) {
    final atSplash = location.startsWith('/splash');

    if (startup is StartupInProgress || startup is StartupFailed) {
      return atSplash ? null : '/splash';
    }

    // Startup ready, profile still loading → keep holding on splash so the
    // greeting never flashes the guest name before the real profile lands.
    if (onboardingCompleted == null) {
      return atSplash ? null : '/splash';
    }

    // Onboarding is no longer a gate (scope §16): an incomplete profile is
    // invited to personalize from a card on home, never redirected away.
    if (atSplash) return '/home';
    return null;
  }
}
