import 'package:flutter_test/flutter_test.dart';

/// Pump a fixed slice of time instead of waiting for stillness.
///
/// The ritual screen's orb breathes and turns for as long as the screen is
/// open — that is the design, not a bug. [WidgetTester.pumpAndSettle] waits
/// for the frame scheduler to go idle, which on this screen never happens, so
/// it spins until it times out and fails the test for the wrong reason.
///
/// Twelve frames of 120ms is 1.4 seconds of animation: comfortably more than
/// a route transition, the staggered entry fades, or a future that resolves
/// immediately, and bounded so an endless animation cannot hang the suite.
Future<void> pumpRitual(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}
