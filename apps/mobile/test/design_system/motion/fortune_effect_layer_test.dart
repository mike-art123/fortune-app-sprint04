import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/design_system/motion/ambient_motion.dart';
import 'package:fortune_app/design_system/motion/fortune_effect_layer.dart';

void main() {
  Widget frame(Widget child) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: SizedBox(width: 300, height: 220, child: child),
      ),
    );
  }

  const layer = FortuneEffectLayer(id: 'coffee', accent: Color(0xFFEFC97F));

  testWidgets('still and settles without a scope', (tester) async {
    await tester.pumpWidget(frame(layer));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('an id with no spec paints nothing', (tester) async {
    await tester.pumpWidget(
      frame(const FortuneEffectLayer(id: 'nope', accent: Color(0xFFFFFFFF))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('the shared clock drives the frames', (tester) async {
    AmbientMotionClock? clock;
    await tester.pumpWidget(
      AmbientMotion(
        child: frame(
          Builder(
            builder: (context) {
              clock = AmbientMotion.maybeClockOf(context);
              return layer;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(clock, isNotNull);
    final before = clock!.elapsedSeconds;
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.elapsedSeconds, greaterThan(before));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving the foreground pauses the clock', (tester) async {
    AmbientMotionClock? clock;
    await tester.pumpWidget(
      AmbientMotion(
        child: frame(
          Builder(
            builder: (context) {
              clock = AmbientMotion.maybeClockOf(context);
              return layer;
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final held = clock!.elapsedSeconds;
    await tester.pump(const Duration(seconds: 1));
    expect(clock!.elapsedSeconds, held);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // A restarted ticker anchors to its first frame (elapsed zero), so one
    // pump proves nothing moved; the second proves the clock runs again.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(clock!.elapsedSeconds, greaterThan(held));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('paints the talisman through a blink', (tester) async {
    await tester.pumpWidget(
      AmbientMotion(
        child: frame(
          const FortuneEffectLayer(
            id: 'dailytalisman',
            accent: Color(0xFFC5A0FF),
          ),
        ),
      ),
    );
    // Walk one full period in small steps so frames land inside the blink.
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CustomPaint), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion never starts the ticker', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: AmbientMotion(child: frame(layer)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
