import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/history/application/history_controller.dart';
import 'package:fortune_app/features/history/domain/history_repository.dart';
import 'package:fortune_app/features/profile/application/profile_controller.dart';
import 'package:fortune_app/features/profile/domain/user_profile.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/recommendations/presentation/widgets/next_fortunes_strip.dart';
import 'package:go_router/go_router.dart';

class FakeHistory implements HistoryRepository {
  FakeHistory(this.items);

  final List<Reading> items;
  int calls = 0;

  @override
  Future<Result<ReadingListPage>> list({String? cursor}) async {
    calls++;
    return Success(ReadingListPage(items: items, nextCursor: null));
  }

  @override
  Future<Result<Reading>> byId(String id) async => const ResultFailure(
        AppFailure(kind: FailureKind.notFound, messageKey: 'notFound'),
      );

  @override
  Future<Result<int>> clear() async => const Success(0);

  @override
  Future<Result<int>> deleteById(String id) async => const Success(0);
}

class OnProfile extends ProfileController {
  @override
  Future<UserProfile?> build() async => const UserProfile(
        displayName: 'علی',
        birthMonth: 'MEHR',
        onboardingCompleted: true,
      );
}

class OptedOutProfile extends ProfileController {
  @override
  Future<UserProfile?> build() async => const UserProfile(
        displayName: 'علی',
        birthMonth: 'MEHR',
        onboardingCompleted: true,
        personalizationOptOut: true,
      );
}

Widget host({
  required ProfileController Function() profile,
  required HistoryRepository history,
}) {
  final router = GoRouter(
    initialLocation: '/reading',
    routes: [
      GoRoute(
        path: '/reading',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(
            child: NextFortunesStrip(fortuneId: 'hafez'),
          ),
        ),
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
      profileControllerProvider.overrideWith(profile),
      historyRepositoryProvider.overrideWithValue(history),
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

/// A suggestion is a courtesy: it explains itself, it opens through the same
/// map as everything else, and it disappears entirely the moment someone says
/// they do not want it.
void main() {
  testWidgets('offers where to go next, with the reason in view', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(profile: OnProfile.new, history: FakeHistory(const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('بعد از این'), findsOneWidget);
    expect(find.text('هم‌خانوادهٔ چیزی که همین حالا خواندی'), findsWidgets);
  });

  testWidgets('a card opens through the shared destination map', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(profile: OnProfile.new, history: FakeHistory(const [])),
    );
    await tester.pumpAndSettle();

    // After «فال حافظ» the first of its family is the coffee ritual.
    await tester.tap(find.text('فال قهوه'));
    await tester.pumpAndSettle();
    expect(find.text('ritual-stub-coffee'), findsOneWidget);
  });

  testWidgets('says nothing at all when personalization is off', (
    tester,
  ) async {
    final history = FakeHistory(const []);
    await tester.pumpWidget(
      host(profile: OptedOutProfile.new, history: history),
    );
    await tester.pumpAndSettle();

    expect(find.text('بعد از این'), findsNothing);
    // And it does not even look at the history to decide that.
    expect(history.calls, 0);
  });
}
