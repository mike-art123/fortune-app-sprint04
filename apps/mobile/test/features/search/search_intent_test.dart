import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/routing/fortune_destinations.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';
import 'package:fortune_app/features/search/domain/search_action.dart';
import 'package:fortune_app/features/search/domain/search_intent.dart';

String? _path(String raw) {
  final action = SearchIntents.match(raw)?.action;
  return switch (action) {
    OpenDestinationAction(:final path) => path,
    OpenFortuneAction(:final path) => path,
    _ => null,
  };
}

/// Sentences people actually say. Every one of them is answered by rules, not
/// by a model — offline, free, and the same answer every time.
const _asks = <String, String>{
  'برام یه فال بگیر': '/ritual/daily',
  'فالم رو بگو': '/ritual/daily',
  'امروز چی میشه': '/ritual/daily',
  'یه جواب کوتاه می‌خوام': '/ritual/yesno',
  'خوابم رو تعبیر کن': '/ritual/dream',
  'تاریخچه‌ام رو ببین': '/history',
  'فال‌های قبلی من': '/history',
  'می‌خوام اسمم رو عوض کنم': '/profile',
  'پروفایلم را باز کن': '/profile',
  'اشتراکم تمام شده': '/vip',
  'چه فالی داری؟': '/fortunes',
};

void main() {
  group('sentences', () {
    test('each one opens the screen it asked for', () {
      _asks.forEach((ask, path) {
        expect(_path(ask), path, reason: '«$ask» must open $path');
      });
    });

    test('the possessive glued to the noun changes nothing', () {
      expect(_path('سابقه‌ام'), '/history');
      expect(_path('اشتراکم'), '/vip');
    });

    test('a match always says what it will open', () {
      for (final ask in _asks.keys) {
        final match = SearchIntents.match(ask)!;
        expect(match.label, isNotEmpty);
        expect(match.hint, isNotEmpty);
      }
    });
  });

  group('restraint', () {
    test('a named fortune is left to the index', () {
      expect(SearchIntents.match('فال حافظ'), isNull);
      expect(SearchIntents.match('فال قهوه'), isNull);
      expect(SearchIntents.match('دیوان'), isNull);
    });

    test('small talk and noise ask nothing', () {
      expect(SearchIntents.match('سلام خوبی'), isNull);
      expect(SearchIntents.match('zzzzqqqq'), isNull);
      expect(SearchIntents.match('   '), isNull);
      expect(SearchIntents.match('؟!'), isNull);
    });
  });

  group('guardrail', () {
    test('a sentence can never invent a destination', () {
      const screens = {'/history', '/profile', '/vip', '/fortunes'};
      for (final ask in _asks.keys) {
        final action = SearchIntents.match(ask)!.action;
        switch (action) {
          case OpenDestinationAction(:final path):
            expect(screens, contains(path));
          case OpenFortuneAction(:final fortuneId, :final path):
            // The id still goes through the one shared map, so an intent can
            // never outrank availability.
            expect(FortuneDestinations.pathFor(fortuneId), path);
          default:
            fail('«$ask» resolved to an action that cannot open anything');
        }
      }
    });

    test('a fortune intent is named the way the registry names it', () {
      for (final ask in _asks.keys) {
        final match = SearchIntents.match(ask)!;
        final action = match.action;
        if (action is OpenFortuneAction) {
          expect(match.label, FortuneRegistry.byId(action.fortuneId)?.title.fa);
        }
      }
    });
  });
}
