import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/access/application/access_flow_controller.dart';
import 'package:fortune_app/features/access/data/access_repository.dart';
import 'package:fortune_app/features/access/domain/access_models.dart';
import 'package:fortune_app/features/fortunes/domain/fal_input.dart';
import 'package:fortune_app/features/reading/application/reading_submission_controller.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/domain/reading_repository.dart';
import 'package:fortune_app/features/reading/presentation/pages/reading_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import 'package:go_router/go_router.dart';

import '../support/reading_page_deps.dart';

class _FakeRepo implements ReadingRepository {
  @override
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
    String? adEntitlementId,
  }) async =>
      Success(
        Reading(
          id: 'clx-flow',
          fortuneId: input.fortuneId,
          title: 'پیامی از دیوان',
          text: 'متنِ خوانش برای تست.',
          createdAt: DateTime(2026),
        ),
      );
}

/// Access always answers «free» here — the flow under test is the submission
/// itself, not the monetization sheet.
class _FakeAccessRepo implements AccessRepository {
  @override
  Future<Result<AccessOptions>> accessOptions(String fortuneId) async {
    return Success(
      AccessOptions(
        fortuneId: fortuneId,
        isVip: false,
        isFreeNow: true,
        freeUsesRemainingToday: 1,
        rewardedAdAvailable: false,
        rewardedAdsRemainingToday: 0,
        accessState: 'free',
      ),
    );
  }

  @override
  Future<Result<MediationSession>> createMediation(
    String fortuneId,
    String idempotencyKey,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<MediationSession>> reportFailure(
    String sessionId,
    int attemptNumber,
    String reason,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<MediationStatus>> status(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancel(String sessionId) async {}
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
    overrides: [
      readingRepositoryProvider.overrideWithValue(_FakeRepo()),
      accessRepositoryProvider.overrideWithValue(_FakeAccessRepo()),
      ...readingScreenDeps(),
    ],
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
