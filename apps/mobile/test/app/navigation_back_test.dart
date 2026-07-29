import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/navigation/app_back.dart';
import 'package:fortune_app/app/navigation/telegram_back_observer.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/platform/telegram_platform_bridge.dart';
import 'package:fortune_app/design_system/components/fortune_app_bar.dart';
import 'package:go_router/go_router.dart';

/// Whole-app back-behaviour audit. Every route resolves back to a real
/// destination — a pushed route pops, a cold deep link falls back to Explore,
/// and a stack root shows no stray control. The in-app back button and the
/// Telegram BackButton are driven by the same [AppBack] logic.

class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FortuneAppBar(title: Text(label)),
      body: Center(child: Text('body-$label')),
    );
  }
}

GoRouter _router(
  String initial, {
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: initial,
    observers: observers,
    routes: [
      GoRoute(path: '/fortunes', builder: (_, __) => const _Page('fortunes')),
      GoRoute(
        path: '/ritual/:id',
        builder: (_, s) => _Page('ritual-${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/vip', builder: (_, __) => const _Page('vip')),
    ],
  );
}

Widget _app(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    locale: SupportedLocales.fa,
    supportedLocales: SupportedLocales.all,
    localizationsDelegates: SupportedLocales.delegates,
    theme: AppTheme.dark(),
  );
}

/// Records what the observer asks of the Telegram bridge.
class _FakeBridge implements TelegramPlatformBridge {
  bool backShown = false;
  int handlerSets = 0;
  void Function()? handler;

  @override
  Future<void> showBackButton() async => backShown = true;
  @override
  Future<void> hideBackButton() async => backShown = false;
  @override
  void setBackButtonHandler(void Function()? h) {
    handlerSets++;
    handler = h;
  }

  @override
  bool get isAvailable => false;
  @override
  String? get initData => null;
  @override
  Future<void> expandViewport() async {}
  @override
  Future<void> hapticImpact() async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> openLink(String url) async {}
  @override
  Future<void> openTelegramLink(String url) async {}
}

void main() {
  group('AppBack.showBack', () {
    test('a poppable route always offers back', () {
      expect(AppBack.showBack(location: '/fortunes', canPop: true), isTrue);
      expect(AppBack.showBack(location: '/ritual/hafez', canPop: true), isTrue);
    });

    test('a stack root at the bottom offers none', () {
      for (final root in const [
        '/splash',
        '/home',
        '/fortunes',
        '/history',
        '/profile',
      ]) {
        expect(
          AppBack.showBack(location: root, canPop: false),
          isFalse,
          reason: root,
        );
      }
    });

    test('a deep route reached cold still offers back (fallback)', () {
      expect(
        AppBack.showBack(location: '/ritual/hafez', canPop: false),
        isTrue,
      );
      expect(AppBack.showBack(location: '/vip', canPop: false), isTrue);
    });
  });

  testWidgets('a cold deep link to a ritual falls back to Explore', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router('/ritual/hafez')));
    await tester.pumpAndSettle();

    expect(find.text('body-ritual-hafez'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('body-fortunes'), findsOneWidget);
  });

  testWidgets('a pushed route pops back to where it came from', (tester) async {
    final router = _router('/fortunes');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    router.push('/vip');
    await tester.pumpAndSettle();
    expect(find.text('body-vip'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('body-fortunes'), findsOneWidget);
  });

  testWidgets('a stack root shows no back control', (tester) async {
    await tester.pumpWidget(_app(_router('/fortunes')));
    await tester.pumpAndSettle();

    expect(find.text('body-fortunes'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the Telegram BackButton tracks the route stack', (tester) async {
    final bridge = _FakeBridge();
    final observer = TelegramBackObserver(bridge);
    final router = _router('/fortunes', observers: [observer]);
    observer.bind(router);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    // Stack root: hidden, handler cleared.
    expect(bridge.backShown, isFalse);
    expect(bridge.handler, isNull);

    router.push('/vip');
    await tester.pumpAndSettle();
    // Deep route: shown, one live handler.
    expect(bridge.backShown, isTrue);
    expect(bridge.handler, isNotNull);

    // Tapping the native back runs the shared handler → pops to Explore.
    bridge.handler!.call();
    await tester.pumpAndSettle();
    expect(find.text('body-fortunes'), findsOneWidget);
    expect(bridge.backShown, isFalse);

    observer.dispose();
    expect(bridge.handler, isNull);
  });
}
