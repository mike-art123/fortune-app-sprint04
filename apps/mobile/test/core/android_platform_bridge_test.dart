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
      shareMessageFromTelegramLink('https://instagram.com/bakhtnegar_fal'),
      isNull,
    );
    expect(shareMessageFromTelegramLink('::bad::'), isNull);
  });

  test('an empty share payload is refused rather than shared blank', () {
    expect(shareMessageFromTelegramLink('https://t.me/share/url'), isNull);
  });
}
