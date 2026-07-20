import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_definition.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';

void main() {
  const fa = Locale('fa');

  test('registry ids are unique', () {
    final ids = FortuneRegistry.all.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every fortune has complete Persian copy', () {
    for (final f in FortuneRegistry.all) {
      expect(f.title.resolve(fa).isNotEmpty, isTrue, reason: f.id);
      expect(f.subtitle.resolve(fa).isNotEmpty, isTrue, reason: f.id);
      expect(f.ritualLine.resolve(fa).isNotEmpty, isTrue, reason: f.id);
      expect(f.cta.resolve(fa).isNotEmpty, isTrue, reason: f.id);
    }
  });

  test('required-input fortunes carry gentle guidance', () {
    for (final f in FortuneRegistry.all) {
      if (f.inputKind == FortuneInputKind.longText || f.inputKind == FortuneInputKind.twoNames) {
        expect(f.guide, isNotNull, reason: '${f.id} needs guidance copy');
      }
    }
  });

  test('byId resolves and rejects', () {
    expect(FortuneRegistry.byId('hafez')?.id, 'hafez');
    expect(FortuneRegistry.byId('nope'), isNull);
  });

  test('photo fortunes are marked soon in Sprint 01', () {
    for (final f in FortuneRegistry.all.where(
      (f) => f.inputKind == FortuneInputKind.photo,
    )) {
      expect(f.isAvailable, isFalse, reason: '${f.id} photo input lands later');
    }
  });
}
