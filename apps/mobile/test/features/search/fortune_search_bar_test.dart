import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/search/presentation/widgets/fortune_search_bar.dart';
import 'package:go_router/go_router.dart';

/// The search bar is the fastest path into a ritual (scope §2): it answers
/// while typing, opens only through a validated destination, and says
/// something calm when it finds nothing.
Widget host() {
  final router = GoRouter(
    initialLocation: '/fortunes',
    routes: [
      GoRoute(
        path: '/fortunes',
        builder: (_, __) => const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: FortuneSearchBar(),
          ),
        ),
      ),
      GoRoute(
        path: '/ritual/:fortuneId',
        builder: (_, state) => Scaffold(
          body: Text('ritual-stub-${state.pathParameters['fortuneId']}'),
        ),
      ),
      GoRoute(
        path: '/coffee',
        builder: (_, __) => const Scaffold(body: Text('coffee-guide-stub')),
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

void main() {
  testWidgets('quiet until asked', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('دنبال چه فالی می‌گردی؟'), findsOneWidget);
    expect(find.text('فال حافظ'), findsNothing);
  });

  testWidgets('a partial name opens the ritual it meant', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'حاف');
    await tester.pumpAndSettle();
    expect(find.text('فال حافظ'), findsOneWidget);

    await tester.tap(find.text('فال حافظ'));
    await tester.pumpAndSettle();
    expect(find.text('ritual-stub-hafez'), findsOneWidget);
  });

  testWidgets('an alias with the Arabic keyboard still lands', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ديوان');
    await tester.pumpAndSettle();

    await tester.tap(find.text('فال حافظ'));
    await tester.pumpAndSettle();
    expect(find.text('ritual-stub-hafez'), findsOneWidget);
  });

  testWidgets('a guided fortune opens its guide, never a dead end', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'فنجان');
    await tester.pumpAndSettle();

    await tester.tap(find.text('فال قهوه'));
    await tester.pumpAndSettle();
    expect(find.text('coffee-guide-stub'), findsOneWidget);
  });

  testWidgets('nothing found is said calmly, and clearing restores quiet', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzzqqqq');
    await tester.pumpAndSettle();
    expect(
      find.text('با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('پاک کردن'));
    await tester.pumpAndSettle();
    expect(
      find.text('با این نام چیزی پیدا نشد؛ از فهرست پایین انتخاب کن.'),
      findsNothing,
    );
  });
}
