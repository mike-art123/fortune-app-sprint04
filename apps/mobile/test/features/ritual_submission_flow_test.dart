import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/fortunes/domain/fal_input.dart';
import 'package:fortune_app/features/reading/application/reading_submission_controller.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/domain/reading_repository.dart';
import 'package:fortune_app/features/reading/presentation/pages/reading_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import 'package:go_router/go_router.dart';

class _FakeRepo implements ReadingRepository {
  @override
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
  }) async => Success(
    Reading(
      id: 'clx-flow',
      fortuneId: input.fortuneId,
      title: 'پیامی از دیوان',
      text: 'متنِ خوانش برای تست.',
      createdAt: DateTime(2026),
    ),
  );
}

Widget host() {
  final router = GoRouter(
    initialLocation: '/ritual/hafez',
    routes: [
      GoRoute(
        path: '/ritual/:fortuneId',
        builder: (_, state) =>
            RitualEntryPage(fortuneId: state.pathParameters['fortuneId']!),
      ),
      GoRoute(
        path: '/reading/:readingId',
        builder: (_, state) => ReadingPage(
          readingId: state.pathParameters['readingId']!,
          reading: state.extra is Reading ? state.extra as Reading : null,
        ),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return ProviderScope(
    overrides: [readingRepositoryProvider.overrideWithValue(_FakeRepo())],
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
  testWidgets('sealing a hafez intention lands on the reading screen', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('فال حافظ را باز کن'));
    await tester.pumpAndSettle();

    expect(find.text('پیامی از دیوان'), findsOneWidget);
    expect(find.textContaining('متنِ خوانش'), findsOneWidget);
  });
}
