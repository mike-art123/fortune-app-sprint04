import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/design_system/components/fortune_button.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/features/history/application/history_controller.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/presentation/pages/reading_page.dart';
import 'package:go_router/go_router.dart';

Widget host(Reading? reading, {List<Override> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/reading',
    routes: [
      GoRoute(
        path: '/reading',
        builder: (_, __) => ReadingPage(readingId: 'clx1', reading: reading),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
    ),
  );
}

Reading _reading() => Reading(
  id: 'clx1',
  fortuneId: 'hafez',
  title: 'پیامی از دیوان',
  text: 'این روزها آرام‌تر از آن‌اند که به چشم می‌آیند.',
  createdAt: DateTime(2026, 1, 7),
);

void main() {
  testWidgets('renders title, reading text, and Persian date', (tester) async {
    await tester.pumpWidget(host(_reading()));
    await tester.pumpAndSettle();

    expect(find.text('پیامی از دیوان'), findsOneWidget);
    expect(find.textContaining('آرام‌تر'), findsOneWidget);
    expect(find.text('۲۰۲۶/۰۱/۰۷'), findsOneWidget);
  });

  testWidgets('save confirms history; share shows coming-soon', (tester) async {
    await tester.pumpWidget(host(_reading()));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FortuneButton>(
      find.widgetWithText(FortuneButton, 'ذخیره'),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.text('ذخیره'));
    await tester.pump();
    expect(find.text('در تاریخچه‌ات ماند.'), findsOneWidget);

    await tester.tap(find.text('اشتراک'));
    await tester.pump();
    expect(find.text('این آیین به‌زودی آماده می‌شود.'), findsOneWidget);
  });

  testWidgets('cold deep link fetches the reading by id', (tester) async {
    await tester.pumpWidget(
      host(
        null,
        overrides: [
          readingByIdProvider('clx1').overrideWith((ref) async => _reading()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('پیامی از دیوان'), findsOneWidget);
  });

  testWidgets('a failed fetch shows honest recovery, never a blank page', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        null,
        overrides: [
          readingByIdProvider('clx1').overrideWith(
            (ref) async => throw const AppFailure(
              kind: FailureKind.notFound,
              messageKey: 'failure.notFound',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('برای دیدنِ خوانش، از مسیرِ آیین وارد شو.'),
      findsOneWidget,
    );
  });
}
