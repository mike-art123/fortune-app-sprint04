import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/design_system/motion/fortune_effects.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_catalog.dart';

void main() {
  test('every home carousel card carries an effect spec', () {
    for (final id in FortuneCatalog.popularIds) {
      expect(fortuneEffectSpec(id), isNotNull, reason: id);
    }
  });

  test('anchors and fields stay inside the artwork', () {
    for (final id in FortuneCatalog.popularIds) {
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
