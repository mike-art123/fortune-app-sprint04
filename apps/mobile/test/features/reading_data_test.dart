import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/fortunes/domain/fal_input.dart';
import 'package:fortune_app/features/reading/data/fal_input_payload.dart';
import 'package:fortune_app/features/reading/data/reading_dto.dart';

void main() {
  group('FalInputPayload', () {
    test('hafez silent intention omits the field', () {
      final json = FalInputPayload.toJson(const IntentionInput(fortuneId: 'hafez'));
      expect(json['fortuneId'], 'hafez');
      expect((json['input'] as Map).containsKey('intention'), isFalse);
    });

    test('love maps both names', () {
      final json = FalInputPayload.toJson(
        const LoveInput(fortuneId: 'love', selfName: 'سارا', otherName: 'امیر'),
      );
      expect(json['input'], {'selfName': 'سارا', 'otherName': 'امیر'});
    });

    test('dream maps narration', () {
      final json = FalInputPayload.toJson(
        const DreamInput(fortuneId: 'dream', narration: 'در باغی سبز'),
      );
      expect(json['input'], {'narration': 'در باغی سبز'});
    });
  });

  group('ReadingDto', () {
    test('parses a valid payload', () {
      final reading = ReadingDto.fromJson({
        'id': 'clx1',
        'fortune': 'hafez',
        'title': 'پیامی از دیوان',
        'reading': 'متنِ خوانش',
        'createdAt': '2026-01-01T08:00:00.000Z',
      });
      expect(reading.id, 'clx1');
      expect(reading.fortuneId, 'hafez');
      expect(reading.createdAt.year, 2026);
    });

    test('rejects a payload missing required fields', () {
      expect(
        () => ReadingDto.fromJson({'id': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
