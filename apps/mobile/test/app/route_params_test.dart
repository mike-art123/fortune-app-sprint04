import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/routing/app_routes.dart';

void main() {
  test('accepts well-formed ids', () {
    expect(RouteParams.isValidId('hafez'), isTrue);
    expect(RouteParams.isValidId('clx_123-ABC'), isTrue);
  });

  test('rejects malformed or hostile ids', () {
    expect(RouteParams.isValidId(null), isFalse);
    expect(RouteParams.isValidId(''), isFalse);
    expect(RouteParams.isValidId('../etc/passwd'), isFalse);
    expect(RouteParams.isValidId('a' * 65), isFalse);
  });

  test('builds paths', () {
    expect(AppRoutes.ritual('hafez'), '/ritual/hafez');
    expect(AppRoutes.reading('r1'), '/reading/r1');
  });
}
