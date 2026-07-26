import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/search/data/search_repository.dart';
import 'package:fortune_app/features/search/domain/search_action.dart';
import 'package:fortune_app/features/search/domain/search_intent.dart';
import 'package:fortune_app/features/search/presentation/widgets/fortune_search_bar.dart';
import 'package:go_router/go_router.dart';

/// A server that answers whatever the test tells it to, without a network.
class FakeSearchRemote implements SearchRepository {
  FakeSearchRemote(this.answer);

  final SearchIntentMatch? answer;
  int asked = 0;
  String? lastQuery;

  @override
  Future<SearchIntentMatch?> interpret(String query) async {
    asked++;
    lastQuery = query;
    return answer;
  }
}

Widget host(SearchRepository? remote) {
  final router = GoRouter(
    initialLocation: '/fortunes',
    routes: [
      GoRoute(
        path: '/fortunes',
        builder: (_, __) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FortuneSearchBar(remote: remote),
          ),
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const Scaffold(body: Text('history-stub')),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: SupportedLocales.fa,
    supportedLocales: SupportedLocales.all,
    localizationsDelegates: SupportedLocales.delegates,
    theme: AppTheme.dark(),
  );
}

/// The AI is the last stage and the only one that costs anything, so it is
/// never automatic: nothing is asked until someone asks for it.
void main() {
  group('the answer is re-validated here', () {
    test('a fortune id becomes a row that opens its ritual', () {
      final match = matchFromInterpretation({
        'kind': 'fortune',
        'fortuneId': 'hafez',
        'titleFa': 'anything the server calls it',
      })!;
      expect(match.label, 'فال حافظ');
      expect((match.action as OpenFortuneAction).path, '/ritual/hafez');
    });

    test('a screen name becomes the screen the app owns', () {
      final match = matchFromInterpretation({
        'kind': 'screen',
        'screen': 'history',
      })!;
      expect(match.label, 'تاریخچهٔ فال‌ها');
      expect((match.action as OpenDestinationAction).path, '/history');
    });

    test('an invented id, an unknown screen or a path is refused', () {
      expect(
        matchFromInterpretation({'kind': 'fortune', 'fortuneId': 'moon'}),
        isNull,
      );
      expect(
        matchFromInterpretation({'kind': 'screen', 'screen': 'admin'}),
        isNull,
      );
      expect(
        matchFromInterpretation({'kind': 'open', 'path': '/vip'}),
        isNull,
      );
      expect(matchFromInterpretation({'kind': 'none'}), isNull);
      expect(matchFromInterpretation(const {}), isNull);
    });

    test('a fortune that is not live is refused, however it was named', () {
      // «coffee» is a guide, «elements» is not in the registry at all: both
      // still go through the shared map rather than around it.
      final coffee = matchFromInterpretation({
        'kind': 'fortune',
        'fortuneId': 'coffee',
      });
      expect((coffee!.action as OpenFortuneAction).path, '/coffee');
      expect(
        matchFromInterpretation({'kind': 'fortune', 'fortuneId': 'elements'}),
        isNull,
      );
    });
  });

  group('the bar', () {
    testWidgets('never asks on its own', (tester) async {
      final remote = FakeSearchRemote(null);
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'یک چیز نامفهوم');
      await tester.pumpAndSettle();

      expect(remote.asked, 0);
      expect(find.text('از دستیار بپرس'), findsOneWidget);
    });

    testWidgets('offers nothing to ask when there is no assistant', (
      tester,
    ) async {
      await tester.pumpWidget(host(null));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'یک چیز نامفهوم');
      await tester.pumpAndSettle();
      expect(find.text('از دستیار بپرس'), findsNothing);
    });

    testWidgets('asks once, then opens what came back', (tester) async {
      final remote = FakeSearchRemote(SearchIntents.forScreen('history'));
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'کارهای قدیمی من کجاست');
      await tester.pumpAndSettle();

      await tester.tap(find.text('از دستیار بپرس'));
      await tester.pumpAndSettle();
      expect(remote.asked, 1);
      expect(remote.lastQuery, 'کارهای قدیمی من کجاست');

      await tester.tap(find.text('تاریخچهٔ فال‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('history-stub'), findsOneWidget);
    });

    testWidgets('a silent answer leaves the calm ending in place', (
      tester,
    ) async {
      final remote = FakeSearchRemote(null);
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzqqqq');
      await tester.pumpAndSettle();
      await tester.tap(find.text('از دستیار بپرس'));
      await tester.pumpAndSettle();

      expect(remote.asked, 1);
      expect(
        find.text('با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.'),
        findsOneWidget,
      );
    });

    testWidgets('the same question is never paid for twice', (tester) async {
      final remote = FakeSearchRemote(null);
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzqqqq');
      await tester.pumpAndSettle();
      await tester.tap(find.text('از دستیار بپرس'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('از دستیار بپرس'));
      await tester.pumpAndSettle();

      expect(remote.asked, 1);
    });

    testWidgets('a named fortune is answered by the index, never asked', (
      tester,
    ) async {
      final remote = FakeSearchRemote(null);
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'حاف');
      await tester.pumpAndSettle();

      expect(find.text('فال حافظ'), findsOneWidget);
      expect(find.text('از دستیار بپرس'), findsNothing);
      expect(remote.asked, 0);
    });
  });
}
