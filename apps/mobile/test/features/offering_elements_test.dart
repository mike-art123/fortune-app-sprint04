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
import 'package:fortune_app/features/ritual_entry/presentation/widgets/paired_names_field.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_ritual.dart';
import '../support/reading_page_deps.dart';
import '../support/seen_disclaimer.dart';

/// Phase 5 — bespoke offering elements. A chosen month, colour or quick intent
/// must actually seed the whisper (and reach the reading pipeline as the
/// intention), and two-name fortunes must render the bond element instead of a
/// bare «و». Every choice flows through the real registry-driven page.
class _CapturingRepo implements ReadingRepository {
  FalInput? lastInput;

  @override
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
    String? adEntitlementId,
  }) async {
    lastInput = input;
    return Success(
      Reading(
        id: 'seed-${input.fortuneId}',
        fortuneId: input.fortuneId,
        title: 'نتیجهٔ ${input.fortuneId}',
        text: 'متنِ آزمایشیِ خوانش برای همین فال.',
        createdAt: DateTime(2026),
      ),
    );
  }
}

class _FreeAccessRepo implements AccessRepository {
  @override
  Future<Result<AccessOptions>> accessOptions(String fortuneId) async {
    return Success(
      AccessOptions(
        fortuneId: fortuneId,
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
  Future<Result<MediationStatus>> complete(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancel(String sessionId) async {}
}

Widget _host(String fortuneId, _CapturingRepo repo) {
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
      readingRepositoryProvider.overrideWithValue(repo),
      accessRepositoryProvider.overrideWithValue(_FreeAccessRepo()),
      seenDisclaimerStorage(),
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

Future<void> _submit(WidgetTester tester, String cta) async {
  await tester.ensureVisible(find.text(cta));
  await tester.tap(find.text(cta));
  await pumpRitual(tester);
}

void main() {
  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('month chooser seeds the intention with the chosen month', (
    tester,
  ) async {
    await phone(tester);
    final repo = _CapturingRepo();
    await tester.pumpWidget(_host('birthmonth', repo));
    await pumpRitual(tester);

    expect(find.text('مهر'), findsOneWidget);
    await tester.ensureVisible(find.text('مهر'));
    await tester.tap(find.text('مهر'));
    await tester.pump();

    await _submit(tester, 'طالعِ ماهت را ببین');
    final input = repo.lastInput;
    expect(input, isA<IntentionInput>());
    expect((input! as IntentionInput).intention, 'مهر');
  });

  testWidgets('colour swatches seed the intention with the chosen colour', (
    tester,
  ) async {
    await phone(tester);
    final repo = _CapturingRepo();
    await tester.pumpWidget(_host('luckycolor', repo));
    await pumpRitual(tester);

    expect(find.text('فیروزه‌ای'), findsOneWidget);
    await tester.ensureVisible(find.text('فیروزه‌ای'));
    await tester.tap(find.text('فیروزه‌ای'));
    await tester.pump();

    await _submit(tester, 'رنگِ امروزت را ببین');
    expect((repo.lastInput! as IntentionInput).intention, 'فیروزه‌ای');
  });

  testWidgets('quick-intent chips seed the whisper with an editable line', (
    tester,
  ) async {
    await phone(tester);
    final repo = _CapturingRepo();
    await tester.pumpWidget(_host('yesno', repo));
    await pumpRitual(tester);

    expect(find.text('آیا پیش بروم؟'), findsOneWidget);
    await tester.ensureVisible(find.text('آیا پیش بروم؟'));
    await tester.tap(find.text('آیا پیش بروم؟'));
    await tester.pump();

    await _submit(tester, 'بله یا خیر را ببین');
    expect((repo.lastInput! as IntentionInput).intention, 'آیا پیش بروم؟');
  });

  testWidgets('two-name fortunes render the bond element, never a bare «و»', (
    tester,
  ) async {
    await phone(tester);
    final repo = _CapturingRepo();
    await tester.pumpWidget(_host('love', repo));
    await pumpRitual(tester);

    expect(find.byType(PairedNamesField), findsOneWidget);
    expect(find.text('و'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'سارا');
    await tester.enterText(find.byType(TextField).last, 'امیر');
    await _submit(tester, 'سازگاری را ببین');

    expect(repo.lastInput, isA<LoveInput>());
    final love = repo.lastInput! as LoveInput;
    expect(love.selfName, 'سارا');
    expect(love.otherName, 'امیر');
  });
}
