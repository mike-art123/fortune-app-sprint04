import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/logging/app_logger.dart';

void main() {
  test('bearer tokens are redacted', () {
    final out = ConsoleLogger.redact('Authorization: Bearer abc.def-123');
    expect(out.contains('abc.def-123'), isFalse);
    expect(out.contains('[redacted]'), isTrue);
  });

  test('telegram initData is redacted', () {
    final out = ConsoleLogger.redact('/auth?initData=query_id%3DAAA&x=1');
    expect(out.contains('query_id'), isFalse);
  });

  test('token json values are redacted', () {
    final out = ConsoleLogger.redact('{"accessToken":"secret-value"}');
    expect(out.contains('secret-value'), isFalse);
  });
}
