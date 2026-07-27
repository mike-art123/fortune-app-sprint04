import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/design_system/motion/ambient_motion.dart';
import 'package:fortune_app/design_system/motion/fortune_effect_layer.dart';
import 'package:fortune_app/design_system/motion/fortune_effect_painter.dart';
import 'package:fortune_app/design_system/motion/fortune_effects.dart';

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

  testWidgets('paints the hourglass through a full cycle', (tester) async {
    await tester.pumpWidget(
      AmbientMotion(
        child: frame(
          const FortuneEffectLayer(
            id: 'future',
            accent: Color(0xFFFFC66B),
          ),
        ),
      ),
    );
    // Seven seconds covers the whole drain and the rewind shimmer.
    for (var i = 0; i < 14; i += 1) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(CustomPaint), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the tea card settles with its warp layer', (tester) async {
    await tester.pumpWidget(
      frame(const FortuneEffectLayer(id: 'tea', accent: Color(0xFFEFC97F))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('paints the tea warp mesh with an image', (tester) async {
    // Decoding an image is real async work: without runAsync it never
    // completes under the test's fake clock and the whole test times out.
    final image = await tester.runAsync(
      () => createTestImage(width: 640, height: 498),
    );
    expect(image, isNotNull);
    final painter = FortuneEffectPainter(
      spec: fortuneEffectSpec('tea')!,
      accent: const Color(0xFFEFC97F),
      seed: effectSeedFor('tea'),
      alignment: Alignment.center,
      artImage: image,
      stillSeconds: 1.7,
    );
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(300, 220));
    recorder.endRecording().dispose();
    image!.dispose();
  });

  testWidgets('paints the ball swirl mesh with an image', (tester) async {
    final image = await tester.runAsync(
      () => createTestImage(width: 640, height: 498),
    );
    expect(image, isNotNull);
    final painter = FortuneEffectPainter(
      spec: fortuneEffectSpec('yesno')!,
      accent: const Color(0xFFC5A0FF),
      seed: effectSeedFor('yesno'),
      alignment: Alignment.center,
      artImage: image,
      stillSeconds: 2.6,
    );
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(300, 220));
    recorder.endRecording().dispose();
    image!.dispose();
  });

  testWidgets('paints the mirror shade with an image', (tester) async {
    final image = await tester.runAsync(
      () => createTestImage(width: 640, height: 498),
    );
    expect(image, isNotNull);
    final painter = FortuneEffectPainter(
      spec: fortuneEffectSpec('mirror')!,
      accent: const Color(0xFFF4EBCF),
      seed: effectSeedFor('mirror'),
      alignment: Alignment.center,
      artImage: image,
      stillSeconds: 1.5,
    );
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(300, 220));
    recorder.endRecording().dispose();
    image!.dispose();
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
