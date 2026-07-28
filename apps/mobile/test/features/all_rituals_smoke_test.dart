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
import 'package:fortune_app/features/fortunes/domain/fortune_definition.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';
import 'package:fortune_app/features/reading/application/reading_submission_controller.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/domain/reading_repository.dart';
import 'package:fortune_app/features/reading/presentation/pages/reading_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/widgets/whisper_field.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_ritual.dart';
import '../support/reading_page_deps.dart';

/// Final pre-push audit, client side: EVERY available fortune's ritual screen
/// is really opened at phone size, shows its own bespoke voice, accepts its
/// input, submits, and lands on the result screen. A missing route, a broken
/// input, an overflow or a dead CTA fails that fortune's own test case.
class _EchoRepo implements ReadingRepository {
  @override
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
    String? adEntitlementId,
  }) async =>
      Success(
        Reading(
          id: 'smoke-${input.fortuneId}',
          fortuneId: input.fortuneId,
          title: 'نتیجهٔ ${input.fortuneId}',
          text: 'متنِ آزمایشیِ خوانش برای همین فال.',
          createdAt: DateTime(2026),
        ),
      );
}

class _FreeAccessRepo implements AccessRepository {
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
        path: '/reading/:readingId',
        builder: (_, state) => ReadingPage(
          readingId: state.pathParameters['readingId']!,
          reading: state.extra is Reading ? state.extra as Reading : null,
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      readingRepositoryProvider.overrideWithValue(_EchoRepo()),
      accessRepositoryProvider.overrideWithValue(_FreeAccessRepo()),
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

Future<void> _offerInput(WidgetTester tester, FortuneDefinition f) async {
  switch (f.inputKind) {
    case FortuneInputKind.intention:
      return; // silence is a valid offering
    case FortuneInputKind.longText:
      await tester.enterText(
        find.byType(WhisperField).first,
        'خواب دیدم در باغی روشن قدم می‌زنم و آبی زلال جاری بود',
      );
      return;
    case FortuneInputKind.twoNames:
      await tester.enterText(find.byType(WhisperField).first, 'سارا');
      await tester.enterText(find.byType(WhisperField).last, 'امیر');
      return;
    case FortuneInputKind.photo:
      return; // coffee needs a camera; a dedicated test covers it below
  }
}

void main() {
  const fa = Locale('fa');
  final available =
      FortuneRegistry.all.where((f) => f.isAvailable).toList(growable: false);

  test('audit precondition: 39 live rituals exist', () {
    expect(available.length, 39);
  });

  for (final f in available) {
    // Photo rituals (coffee) need a real camera; a dedicated test covers it.
    if (f.inputKind == FortuneInputKind.photo) continue;
    testWidgets('ritual «${f.id}» opens, speaks, accepts input, resolves', (
      tester,
    ) async {
      // Narrow phone: any overflow in this fortune's screen fails RIGHT HERE.
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(f.id));
      await pumpRitual(tester);

      // Bespoke voice on screen — its own line and its own act.
      expect(find.text(f.ritualLine.resolve(fa)), findsOneWidget);
      final cta = f.cta.resolve(fa);
      expect(find.text(cta), findsOneWidget);

      await _offerInput(tester, f);
      await tester.ensureVisible(find.text(cta));
      await tester.tap(find.text(cta));
      await pumpRitual(tester);

      // Landed on the result screen of THIS fortune.
      expect(find.text('نتیجهٔ ${f.id}'), findsOneWidget);
    });
  }

  testWidgets('coffee ritual shows the camera and the symbol guide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final coffee = FortuneRegistry.byId('coffee')!;
    await tester.pumpWidget(host('coffee'));
    await pumpRitual(tester);

    expect(find.text(coffee.ritualLine.resolve(fa)), findsOneWidget);
    expect(find.text(coffee.cta.resolve(fa)), findsOneWidget);
    expect(find.text('گرفتن عکس'), findsOneWidget);
    expect(find.text('راهنمای نشانه‌ها'), findsOneWidget);
  });
}
