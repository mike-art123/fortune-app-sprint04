import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';
import 'package:fortune_app/features/search/domain/fortune_search.dart';
import 'package:fortune_app/features/search/domain/search_action.dart';

String _topId(String query) => FortuneSearch.query(query).first.entry.id;

List<String> _ids(String query) =>
    FortuneSearch.query(query).map((r) => r.entry.id).toList();

/// Search is the fastest path to a fortune (scope §2): what a person types —
/// exactly, partially, with the Arabic keyboard or with a typo — must land on
/// the fortune they meant, and never on a route we did not validate.
void main() {
  group('index', () {
    test('covers every fortune in the registry', () {
      expect(FortuneSearch.index.length, FortuneRegistry.all.length);
      for (final fortune in FortuneRegistry.all) {
        final entry = FortuneSearch.index.firstWhere((e) => e.id == fortune.id);
        expect(entry.terms, isNotEmpty);
        expect(entry.title, fortune.title.fa);
      }
    });

    test('every fortune is reachable by its own Persian title', () {
      for (final fortune in FortuneRegistry.all) {
        final ids = _ids(fortune.title.fa);
        expect(
          ids,
          contains(fortune.id),
          reason: 'searching «${fortune.title.fa}» must find ${fortune.id}',
        );
      }
    });
  });

  group('matching', () {
    test('an exact title wins', () {
      expect(_topId('فال حافظ'), 'hafez');
      expect(_topId('تعبیر خواب'), 'dream');
    });

    test('a prefix is enough', () {
      expect(_topId('حاف'), 'hafez');
      expect(_topId('تارو'), 'tarot');
    });

    test('an alias the title never says still lands', () {
      expect(_topId('دیوان'), 'hafez');
      expect(_topId('استخاره'), 'quran');
      expect(_topId('مراقبه'), 'meditation');
      expect(_topId('فنجان'), 'coffee');
    });

    test('the Arabic keyboard and نیم‌فاصله change nothing', () {
      expect(_topId('فال حافظي'), 'hafez');
      expect(_topId('تعبیر‌خواب'), 'dream');
    });

    test('a typo in a long word is forgiven', () {
      expect(_topId('مدیتیشین'), 'meditation');
      expect(_topId('لنورمن'), 'lenormand');
    });

    test('a short word is never guessed into another one', () {
      // «گل» must not become «دل»: one letter apart, but both are real.
      expect(_topId('گل'), 'luckyflower');
      expect(_ids('گل'), isNot(contains('love')));
    });

    test('empty or meaningless input asks nothing', () {
      expect(FortuneSearch.query(''), isEmpty);
      expect(FortuneSearch.query('   '), isEmpty);
      expect(FortuneSearch.query('؟!'), isEmpty);
      expect(FortuneSearch.query('zzzzqqqq'), isEmpty);
    });

    test('results are capped and ordered by relevance', () {
      final results = FortuneSearch.query('فال', limit: 4);
      expect(results.length, 4);
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].score, greaterThanOrEqualTo(results[i].score));
      }
    });
  });

  group('actions (navigation guardrail)', () {
    test('a live fortune resolves to its ritual path', () {
      final action = SearchActions.forFortune('hafez');
      expect(action, isA<OpenFortuneAction>());
      expect((action as OpenFortuneAction).path, '/ritual/hafez');
    });

    test('a guided fortune resolves to its guide, not to «به‌زودی»', () {
      final action = SearchActions.forFortune('coffee');
      expect(action, isA<OpenFortuneAction>());
      expect((action as OpenFortuneAction).path, '/coffee');
    });

    test('an unknown or malformed id can never navigate', () {
      expect(SearchActions.forFortune('nope'), isA<NoSearchAction>());
      expect(SearchActions.forFortune('../admin'), isA<NoSearchAction>());
      expect(SearchActions.forFortune(''), isA<NoSearchAction>());
    });

    test('no fortune the search can show is a dead end', () {
      for (final entry in FortuneSearch.index) {
        expect(
          SearchActions.forFortune(entry.id),
          isNot(isA<NoSearchAction>()),
          reason: '${entry.id} is searchable and must resolve to an action',
        );
      }
    });
  });
}
