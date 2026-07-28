import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/app_startup_state.dart';
import 'package:fortune_app/app/routing/route_guards.dart';

/// Onboarding is no longer a gate (scope §16): startup decides first, then the
/// profile only holds the splash while it loads. Once known, the app always
/// goes home — an incomplete profile is invited to personalize from a card on
/// home, never redirected to a full-screen step.
void main() {
  String? redirect(
    AppStartupState startup,
    bool? onboardingCompleted,
    String location,
  ) =>
      RouteGuards.redirect(
        startup: startup,
        onboardingCompleted: onboardingCompleted,
        location: location,
      );

  group('startup not ready', () {
    test('holds on splash while starting', () {
      expect(redirect(const StartupInProgress(), null, '/splash'), isNull);
      expect(redirect(const StartupInProgress(), null, '/home'), '/splash');
      expect(
        redirect(const StartupInProgress(), null, '/ritual/hafez'),
        '/splash',
      );
    });

    test('holds on splash after a failed startup (retry lives there)', () {
      expect(redirect(const StartupFailed('x'), null, '/splash'), isNull);
      expect(redirect(const StartupFailed('x'), null, '/home'), '/splash');
    });
  });

  group('startup ready, profile unknown', () {
    test('keeps holding on splash — no flash before the gate decides', () {
      expect(redirect(const StartupReady(), null, '/splash'), isNull);
      expect(redirect(const StartupReady(), null, '/home'), '/splash');
      expect(redirect(const StartupReady(), null, '/onboarding'), '/splash');
    });
  });

  group('onboarding incomplete is no longer a gate', () {
    test('splash resolves straight to home', () {
      expect(redirect(const StartupReady(), false, '/splash'), '/home');
    });

    test('a deep link is left untouched — no onboarding detour', () {
      expect(redirect(const StartupReady(), false, '/ritual/hafez'), isNull);
    });

    test('home is reachable directly', () {
      expect(redirect(const StartupReady(), false, '/home'), isNull);
    });
  });

  group('onboarding complete', () {
    test('/onboarding is left to the page (it owns the welcome step)', () {
      expect(redirect(const StartupReady(), true, '/onboarding'), isNull);
    });

    test('splash resolves to home', () {
      expect(redirect(const StartupReady(), true, '/splash'), '/home');
    });

    test('normal navigation is untouched', () {
      expect(redirect(const StartupReady(), true, '/home'), isNull);
      expect(redirect(const StartupReady(), true, '/ritual/hafez'), isNull);
      expect(redirect(const StartupReady(), true, '/history'), isNull);
    });
  });
}
