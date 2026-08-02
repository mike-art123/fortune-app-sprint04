import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/profile/presentation/pages/profile_placeholder_page.dart';

/// An invitation carries a link, and the link has to suit the phone that sent
/// it. The iPhone build used to hand out a Google Play address — broken for
/// whoever received it, and the sort of thing App Review Guideline 2.3.10
/// asks an app not to carry.
///
/// The Android case is here for the opposite reason: to prove the Play build
/// still says exactly what it said before, so this change cannot quietly
/// follow the shared file into the store listing that is already live.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('an iPhone invitation names no other store', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(inviteDestination(), 'https://app.bakhtnegar.com');
    expect(inviteDestination(), isNot(contains('play.google.com')));
  });

  test('the Play build still hands out its own listing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(
      inviteDestination(),
      'https://play.google.com/store/apps/details?id=com.bakhtnegar.app',
    );
  });
}
