import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/app_startup_state.dart';
import 'package:fortune_app/app/routing/route_guards.dart';

/// The onboarding gate (scope §16): startup first, then profile. The main UI
/// must never flash before onboarding is decided, deep links must continue to
/// their original destination, and a completed profile makes /onboarding
/// unreachable.
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

  group('onboarding incomplete', () {
    test('splash flows into onboarding with home as the destination', () {
      expect(
        redirect(const StartupReady(), false, '/splash'),
        '/onboarding?next=%2Fhome',
      );
    });

    test('a deep link rides along encoded and continues afterwards', () {
      expect(
        redirect(const StartupReady(), false, '/ritual/hafez'),
        '/onboarding?next=%2Fritual%2Fhafez',
      );
    });

    test('already at onboarding stays put', () {
      expect(redirect(const StartupReady(), false, '/onboarding'), isNull);
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
