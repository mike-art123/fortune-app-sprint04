import '../app_startup_state.dart';

/// Navigation gates (doc 51 §12.3 + scope §16).
///
/// Order of truth: startup first (auth/bootstrap), then the profile. While
/// either is still unknown the app holds on splash — the main UI must never
/// flash before onboarding is decided. Once startup is ready:
///  - onboarding incomplete → /onboarding (the intended destination rides
///    along as ?next= so deep links continue where they meant to go);
///  - onboarding complete → splash resolves to home, and /onboarding is left
///    to the page itself: it owns the welcome step it just earned, and sends
///    an already-onboarded visitor onwards (see OnboardingPage).
abstract final class RouteGuards {
  static String? redirect({
    required AppStartupState startup,
    required bool? onboardingCompleted,
    required String location,
  }) {
    final atSplash = location.startsWith('/splash');
    final atOnboarding = location.startsWith('/onboarding');

    if (startup is StartupInProgress || startup is StartupFailed) {
      return atSplash ? null : '/splash';
    }

    // Startup ready, profile still loading → keep holding on splash.
    if (onboardingCompleted == null) {
      return atSplash ? null : '/splash';
    }

    if (!onboardingCompleted) {
      if (atOnboarding) return null;
      final next = atSplash ? '/home' : location;
      return '/onboarding?next=${Uri.encodeComponent(next)}';
    }

    if (atSplash) return '/home';
    return null;
  }
}
