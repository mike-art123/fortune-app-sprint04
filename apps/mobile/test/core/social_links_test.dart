import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/config/social_links_switch.dart';

/// The invite card and the Telegram/Instagram tiles are dropped from the first
/// iOS submission, and from nothing else. The switch defaults to on, and only
/// ios.yml passes the define that turns it off — so this test runs the way the
/// web bundle and the Play build compile, with no defines at all, and pins
/// them to the behaviour they have today.
///
/// If this ever goes red, three features have quietly vanished from two live
/// products, which is a far worse outcome than the review risk it was written
/// to manage.
void main() {
  test('web and Play keep all three doors out of the app', () {
    expect(kSocialLinksEnabled, isTrue);
  });
}
