import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/routing/app_routes.dart';
import 'package:fortune_app/app/routing/start_intent.dart';

/// The `?start=` parameter carried by notification buttons maps to exactly
/// two places — and anything unexpected maps to nowhere, never to a crash.
void main() {
  test('daily leads to the daily ritual', () {
    expect(StartIntent.targetFor('daily'), AppRoutes.ritual('daily'));
  });

  test('history leads to the history page', () {
    expect(StartIntent.targetFor('history'), AppRoutes.historyPath);
  });

  test('anything else leads nowhere', () {
    expect(StartIntent.targetFor(null), isNull);
    expect(StartIntent.targetFor(''), isNull);
    expect(StartIntent.targetFor('hafez'), isNull);
    expect(StartIntent.targetFor('<script>'), isNull);
  });
}
