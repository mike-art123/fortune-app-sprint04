import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/widgets/paired_names_field.dart';
import 'package:fortune_app/features/ritual_entry/presentation/widgets/whisper_field.dart';
import 'package:go_router/go_router.dart';

/// The page now renders its back affordance through the router (FortuneAppBar
/// reads GoRouter/GoRouterState), so the host must provide a real GoRouter —
/// the same shape the CI-green smoke suite uses.
Widget host(String fortuneId) {
  final router = GoRouter(
    initialLocation: '/ritual/$fortuneId',
    routes: [
      GoRoute(
        path: '/ritual/:fortuneId',
        builder: (_, state) =>
            RitualEntryPage(fortuneId: state.pathParameters['fortuneId']!),
      ),
      GoRoute(
        path: '/fortunes',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('explore-stub'))),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
    ),
  );
}

void main() {
  testWidgets('hafez entry shows ritual line, whisper, and CTA', (
    tester,
  ) async {
    await tester.pumpWidget(host('hafez'));
    await tester.pumpAndSettle();

    expect(find.text('نیتت را در دل نگه دار.'), findsOneWidget);
    expect(find.byType(WhisperField), findsOneWidget);
    expect(find.text('فال حافظ را باز کن'), findsOneWidget);
  });

  testWidgets('love entry renders the paired-names bond, not a bare و', (
    tester,
  ) async {
    await tester.pumpWidget(host('love'));
    await tester.pumpAndSettle();

    // Interior phase 5: the two whispers are joined by the bond element in
    // the family accent — the lone «و» between form fields is gone.
    expect(find.byType(PairedNamesField), findsOneWidget);
    expect(find.byType(WhisperField), findsNWidgets(2));
    expect(find.text('و'), findsNothing);
  });

  testWidgets('love: sealing with one name shows gentle guidance', (
    tester,
  ) async {
    await tester.pumpWidget(host('love'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(WhisperField).first, 'سارا');
    await tester.tap(find.text('سازگاری را ببین'));
    await tester.pumpAndSettle();

    expect(
      find.text('برای دیدنِ سازگاری، هر دو نام را بنویس.'),
      findsOneWidget,
    );
  });

  testWidgets('the back button under the CTA leaves the ritual', (
    tester,
  ) async {
    await tester.pumpWidget(host('hafez'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('بازگشت'));
    await tester.tap(find.text('بازگشت'));
    await tester.pumpAndSettle();

    expect(find.text('explore-stub'), findsOneWidget);
  });

  testWidgets('unknown fortune id shows branded recovery', (tester) async {
    await tester.pumpWidget(host('nonsense'));
    await tester.pumpAndSettle();

    expect(find.text('این صفحه پیدا نشد'), findsOneWidget);
  });

  testWidgets('entry renders right-to-left under Persian locale', (
    tester,
  ) async {
    await tester.pumpWidget(host('hafez'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(RitualEntryPage));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
