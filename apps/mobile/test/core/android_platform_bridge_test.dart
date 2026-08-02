import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/platform/android_platform_bridge.dart';

void main() {
  test('a t.me share link becomes one share-sheet message', () {
    final url = Uri(
      scheme: 'https',
      host: 't.me',
      path: 'share/url',
      queryParameters: {
        'url': 'https://t.me/Bakhtnegarbot/Bakhtnegar',
        'text': 'با بخت‌نگار هر روز فال بگیر ✨',
      },
    ).toString();

    const expected =
        'با بخت‌نگار هر روز فال بگیر ✨\nhttps://t.me/Bakhtnegarbot/Bakhtnegar';
    expect(shareMessageFromTelegramLink(url), expected);
  });

  test('non-share telegram links and other urls stay external', () {
    expect(shareMessageFromTelegramLink('https://t.me/bakhtnegar'), isNull);
    expect(
      shareMessageFromTelegramLink('https://instagram.com/bakhtnegar_app'),
      isNull,
    );
    expect(shareMessageFromTelegramLink('::bad::'), isNull);
  });

  test('an empty share payload is refused rather than shared blank', () {
    expect(shareMessageFromTelegramLink('https://t.me/share/url'), isNull);
  });

  // iOS 26 rejects a zero-sized anchor and the share sheet never opens, which
  // is how «دعوت از دوستان» came to do nothing at all on an iPhone. The one
  // property that matters is that this rectangle is never empty.
  test('the share sheet is handed a rectangle that is not empty', () {
    final anchor = shareAnchor();

    expect(anchor.isEmpty, isFalse);
    expect(anchor.width, greaterThan(0));
    expect(anchor.height, greaterThan(0));
    // NaN slips through `> 0` unnoticed, so say it out loud.
    expect(anchor.width.isFinite, isTrue);
    expect(anchor.height.isFinite, isTrue);
  });
}
