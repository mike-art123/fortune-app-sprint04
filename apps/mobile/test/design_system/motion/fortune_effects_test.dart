import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/design_system/motion/fortune_effects.dart';
import 'package:fortune_app/design_system/motion/fortune_hourglass.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_catalog.dart';

void main() {
  test('every home carousel card carries an effect spec', () {
    for (final id in FortuneCatalog.popularIds) {
      expect(fortuneEffectSpec(id), isNotNull, reason: id);
    }
  });

  test('every catalog card carries an effect spec', () {
    for (final group in FortuneCatalog.groups) {
      for (final item in group.items) {
        expect(fortuneEffectSpec(item.$1), isNotNull, reason: item.$1);
      }
    }
  });

  test('anchors and fields stay inside the artwork', () {
    for (final group in FortuneCatalog.groups) {
      for (final item in group.items) {
        final id = item.$1;
        final spec = fortuneEffectSpec(id)!;
        expect(spec.layers, isNotEmpty, reason: id);
        for (final layer in spec.layers) {
          expect(layer.anchor.dx, inInclusiveRange(0, 1), reason: id);
          expect(layer.anchor.dy, inInclusiveRange(0, 1), reason: id);
          expect(layer.spread.dx, inInclusiveRange(0, 0.5), reason: id);
          expect(layer.spread.dy, inInclusiveRange(0, 0.5), reason: id);
          expect(layer.intensity, inInclusiveRange(0.1, 1.3), reason: id);
          expect(layer.count, inInclusiveRange(0, 24), reason: id);
        }
      }
    }
  });

  test('particle randomness is deterministic and well spread', () {
    final seed = effectSeedFor('coffee');
    for (var i = 0; i < 20; i += 1) {
      final first = effectRandom(seed, i, 3);
      final second = effectRandom(seed, i, 3);
      expect(first, second);
      expect(first, inInclusiveRange(0, 1));
    }
    final values = <double>{
      for (var i = 0; i < 20; i += 1) effectRandom(seed, i, 3),
    };
    expect(values.length, greaterThan(15));
  });

  test('seeds are stable per id and differ across cards', () {
    expect(effectSeedFor('hafez'), effectSeedFor('hafez'));
    expect(effectSeedFor('hafez'), isNot(effectSeedFor('candle')));
  });

  test('the talisman blinks: shut once a period, open the rest', () {
    final spec = fortuneEffectSpec('dailytalisman')!;
    final blink = spec.layers.firstWhere(
      (layer) => layer.kind == FortuneEffectKind.blink,
    );
    final eye = blink.eye!;
    final seed = effectSeedFor('dailytalisman');
    var sawShut = false;
    var openCount = 0;
    const steps = 400;
    for (var i = 0; i < steps; i += 1) {
      final t = i * (2 * eye.blinkPeriod) / steps;
      final c = blinkClosure(seed, t, period: eye.blinkPeriod);
      expect(c, inInclusiveRange(0, 1));
      expect(c, blinkClosure(seed, t, period: eye.blinkPeriod));
      if (c >= 0.99) sawShut = true;
      if (c == 0) openCount += 1;
    }
    expect(sawShut, isTrue);
    expect(openCount, greaterThan(steps ~/ 2));
  });

  test('the talisman eye opening stays inside the artwork', () {
    final spec = fortuneEffectSpec('dailytalisman')!;
    final eye = spec.layers
        .firstWhere((layer) => layer.kind == FortuneEffectKind.blink)
        .eye!;
    expect(eye.xLeft, greaterThanOrEqualTo(0));
    expect(eye.xRight, lessThanOrEqualTo(kFortuneArtSize.width));
    expect(eye.xLeft, lessThan(eye.xRight));
    for (var i = 0; i <= 40; i += 1) {
      final u = i / 40;
      final top = eye.upperY(u);
      final bottom = eye.lowerY(u);
      expect(top, inInclusiveRange(0, kFortuneArtSize.height));
      expect(bottom, inInclusiveRange(0, kFortuneArtSize.height));
      if (u > 0.1 && u < 0.9) {
        expect(bottom - top, greaterThan(10));
      }
    }
    expect((eye.upperY(0) - eye.lowerY(0)).abs(), lessThan(3));
    expect((eye.upperY(1) - eye.lowerY(1)).abs(), lessThan(3));
  });

  test('the hourglass runs its six seconds and turns back', () {
    final spec = fortuneEffectSpec('future')!;
    final layer = spec.layers.firstWhere(
      (l) => l.kind == FortuneEffectKind.hourglass,
    );
    final hg = layer.hourglass!;
    expect(hg.drainSeconds, 6);
    expect(hourglassProgress(0), 0);
    expect(hourglassProgress(hg.drainSeconds - 0.001), closeTo(1, 0.001));
    final period = hg.drainSeconds + hg.rewindSeconds;
    expect(hourglassProgress(period - 0.0001), lessThan(0.01));
    for (var i = 0; i < 200; i += 1) {
      final t = i * period / 100;
      final c = hourglassProgress(t);
      expect(c, inInclusiveRange(0, 1));
      expect(c, hourglassProgress(t));
      expect(hourglassProgress(t + period), closeTo(c, 1e-9));
    }
    expect(hourglassRewind(hg.drainSeconds / 2), 0);
    expect(
      hourglassRewind(hg.drainSeconds + hg.rewindSeconds / 2),
      closeTo(0.5, 0.001),
    );
  });

  test('the hourglass geometry stays inside the artwork', () {
    final hg = fortuneEffectSpec('future')!
        .layers
        .firstWhere((l) => l.kind == FortuneEffectKind.hourglass)
        .hourglass!;
    expect(hg.topX0, lessThan(hg.topX1));
    expect(hg.botX0, lessThan(hg.botX1));
    for (var i = 0; i <= 40; i += 1) {
      final x = hg.topX0 + (hg.topX1 - hg.topX0) * i / 40;
      expect(hg.topAt(x), inInclusiveRange(0, kFortuneArtSize.height));
      expect(hg.botAt(x), greaterThanOrEqualTo(hg.topAt(x)));
      final bx = hg.botX0 + (hg.botX1 - hg.botX0) * i / 40;
      final crest = hg.crestAt(bx);
      expect(crest, inInclusiveRange(0, kFortuneArtSize.height));
      expect(hg.fullCrestAt(bx), lessThanOrEqualTo(crest));
    }
    for (var i = 0; i <= 20; i += 1) {
      final y = hg.topY0 + (hg.topY1 - hg.topY0) * i / 20;
      expect(hg.spanLeftAt(y), lessThan(hg.spanRightAt(y)));
    }
    expect(hg.glassTone.length % 3, 0);
    expect(hg.aboveTone.length % 3, 0);
    expect(hg.crestTone.length % 3, 0);
  });

  test('cover mapping matches the centre-cover crop', () {
    const size = Size(300, 300);
    final centre = mapCoverPoint(
      const Offset(0.5, 0.5),
      size,
      Alignment.center,
    );
    expect(centre.dx, closeTo(150, 0.001));
    expect(centre.dy, closeTo(150, 0.001));

    final origin = mapCoverPoint(Offset.zero, size, const Alignment(-1, -1));
    expect(origin.dx, closeTo(0, 0.001));
    expect(origin.dy, closeTo(0, 0.001));
  });
}
