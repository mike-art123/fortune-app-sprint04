import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/fortunes/domain/fal_input.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';

void main() {
  final hafez = FortuneRegistry.byId('hafez')!;
  final dream = FortuneRegistry.byId('dream')!;
  final love = FortuneRegistry.byId('love')!;

  test('intention: empty is a valid quiet offering', () {
    final outcome = FalInputFactory.build(fortune: hafez, primary: '   ');
    expect(outcome, isA<OfferingReady>());
    final input = (outcome as OfferingReady).input as IntentionInput;
    expect(input.intention, isNull);
  });

  test('intention: text is trimmed and kept', () {
    final outcome = FalInputFactory.build(
      fortune: hafez,
      primary: '  دلم روشن شود  ',
    );
    final input = ((outcome as OfferingReady).input) as IntentionInput;
    expect(input.intention, 'دلم روشن شود');
  });

  test('dream: too few words returns gentle guidance', () {
    final outcome = FalInputFactory.build(fortune: dream, primary: 'خواب');
    expect(outcome, isA<OfferingNeedsMore>());
    expect((outcome as OfferingNeedsMore).guidance.fa, dream.guide!.fa);
  });

  test('dream: enough words seals a DreamInput', () {
    final outcome = FalInputFactory.build(
      fortune: dream,
      primary: 'در باغی سبز راه می‌رفتم',
    );
    expect(outcome, isA<OfferingReady>());
    expect((outcome as OfferingReady).input, isA<DreamInput>());
  });

  test('love: one missing name returns guidance', () {
    final outcome = FalInputFactory.build(
      fortune: love,
      primary: 'سارا',
      secondary: '',
    );
    expect(outcome, isA<OfferingNeedsMore>());
  });

  test('love: both names seal a LoveInput', () {
    final outcome = FalInputFactory.build(
      fortune: love,
      primary: 'سارا',
      secondary: 'امیر',
    );
    final input = ((outcome as OfferingReady).input) as LoveInput;
    expect(input.selfName, 'سارا');
    expect(input.otherName, 'امیر');
  });

  test('redacted description never leaks personal content', () {
    final input = (FalInputFactory.build(
      fortune: dream,
      primary: 'رازِ خیلی شخصی درباره‌ی خواب',
    ) as OfferingReady)
        .input;
    expect(input.redactedDescription.contains('راز'), isFalse);
  });
}
