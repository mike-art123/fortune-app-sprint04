import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/app_startup_state.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/profile/application/profile_controller.dart';
import 'package:fortune_app/features/profile/data/profile_repository.dart';
import 'package:fortune_app/features/profile/domain/user_profile.dart';
import 'package:fortune_app/features/profile/presentation/pages/onboarding_page.dart';
import 'package:fortune_app/features/profile/presentation/widgets/month_pill.dart';
import 'package:fortune_app/features/ritual_entry/presentation/widgets/whisper_field.dart';
import 'package:fortune_app/features/splash/presentation/controllers/startup_controller.dart';
import 'package:go_router/go_router.dart';

/// Onboarding is the first thing a person ever sees (scope §16): every step,
/// validation, retry and the final hand-off to the original destination is
/// proven here — a broken first impression fails right here.
class _ReadyStartup extends StartupController {
  @override
  Future<AppStartupState> build() async => const StartupReady();
}

class _FakeProfileRepo implements ProfileRepository {
  _FakeProfileRepo({this.alreadyCompleted = false});

  final bool alreadyCompleted;
  Result<UserProfile>? nextCompleteResult;
  String? sentName;
  String? sentMonth;
  int completeCalls = 0;

  @override
  Future<Result<UserProfile>> fetch() async {
    return Success(
      UserProfile(
        displayName: alreadyCompleted ? 'علی' : null,
        birthMonth: alreadyCompleted ? 'MEHR' : null,
        onboardingCompleted: alreadyCompleted,
      ),
    );
  }

  @override
  Future<Result<UserProfile>> completeOnboarding({
    required String displayName,
    required String birthMonth,
  }) async {
    completeCalls++;
    sentName = displayName;
    sentMonth = birthMonth;
    return nextCompleteResult ??
        Success(
          UserProfile(
            displayName: displayName.trim(),
            birthMonth: birthMonth,
            onboardingCompleted: true,
          ),
        );
  }

  @override
  Future<Result<UserProfile>> update({
    String? displayName,
    String? birthMonth,
  }) async {
    throw UnimplementedError();
  }
}

Widget host(_FakeProfileRepo repo, {String? next}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => OnboardingPage(next: next),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/ritual/:fortuneId',
        builder: (_, state) => Scaffold(
          body: Text('ritual-stub-${state.pathParameters['fortuneId']}'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      startupControllerProvider.overrideWith(_ReadyStartup.new),
      profileRepositoryProvider.overrideWithValue(repo),
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
  testWidgets('full ritual: name → month → welcome → original destination', (
    tester,
  ) async {
    final repo = _FakeProfileRepo();
    await tester.pumpWidget(host(repo, next: '/ritual/hafez'));
    await tester.pumpAndSettle();

    // Step 0: the question and the whisper for the name.
    expect(
      find.text('دوست داری بخت‌نگار تو را با چه نامی صدا کند؟'),
      findsOneWidget,
    );

    // «ادامه» refuses an empty name — still on step 0.
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(
      find.text('دوست داری بخت‌نگار تو را با چه نامی صدا کند؟'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(WhisperField), 'علی');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();

    // Step 1: all twelve months are offered.
    expect(find.text('ماه تولدت کدام است؟'), findsOneWidget);
    expect(find.byType(MonthPill), findsNWidgets(12));

    // «بازگشت» preserves the typed name.
    await tester.tap(find.text('بازگشت'));
    await tester.pumpAndSettle();
    expect(find.text('علی'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();

    // «ادامه» refuses a missing month — still on step 1, nothing sent.
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(find.text('ماه تولدت کدام است؟'), findsOneWidget);
    expect(repo.completeCalls, 0);

    await tester.tap(find.text('مهر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();

    // Saved exactly once with the chosen values; welcome uses the name.
    expect(repo.completeCalls, 1);
    expect(repo.sentName, 'علی');
    expect(repo.sentMonth, 'MEHR');
    expect(find.text('خوش آمدی، علی.'), findsOneWidget);

    // «بریم» continues to the original deep-link destination.
    await tester.tap(find.text('بریم'));
    await tester.pumpAndSettle();
    expect(find.text('ritual-stub-hafez'), findsOneWidget);
  });

  testWidgets('a failed save shows the message and keeps every choice', (
    tester,
  ) async {
    final repo = _FakeProfileRepo()
      ..nextCompleteResult = const ResultFailure(
        AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout'),
      );
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(WhisperField), 'سارا');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();

    // Still on step 1 with an error message; the choice survived.
    expect(repo.completeCalls, 1);
    expect(find.text('ماه تولدت کدام است؟'), findsOneWidget);

    // The retry succeeds and reaches the welcome step.
    repo.nextCompleteResult = null;
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(repo.completeCalls, 2);
    expect(repo.sentMonth, 'DEY');
    expect(find.text('خوش آمدی، سارا.'), findsOneWidget);
  });

  testWidgets('an already-onboarded visitor is never asked again', (
    tester,
  ) async {
    final repo = _FakeProfileRepo(alreadyCompleted: true);
    await tester.pumpWidget(host(repo, next: '/ritual/hafez'));
    await tester.pumpAndSettle();

    expect(repo.completeCalls, 0);
    expect(find.text('ritual-stub-hafez'), findsOneWidget);
  });

  testWidgets('without a next target «بریم» lands on the app fallback', (
    tester,
  ) async {
    final repo = _FakeProfileRepo();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(WhisperField), 'علی');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مهر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بریم'));
    await tester.pumpAndSettle();
    expect(find.text('home-stub'), findsOneWidget);
  });
}
