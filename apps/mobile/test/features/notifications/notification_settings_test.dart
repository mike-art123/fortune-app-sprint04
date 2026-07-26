import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/notifications/application/notification_controller.dart';
import 'package:fortune_app/features/notifications/data/notification_repository.dart';
import 'package:fortune_app/features/notifications/domain/notification_preferences.dart';
import 'package:fortune_app/features/notifications/presentation/widgets/notification_settings_card.dart';

/// Records what the screen asked the server for, and can be told to refuse.
class FakeNotificationRepo implements NotificationRepository {
  FakeNotificationRepo({this.stored = const NotificationPreferences()});

  NotificationPreferences stored;
  bool refuse = false;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Result<NotificationPreferences>> fetch() async => Success(stored);

  @override
  Future<Result<NotificationPreferences>> update({
    bool? dailyFortune,
    bool? streakReminder,
    bool? weeklySummary,
    int? quietFromHour,
    int? quietToHour,
    int? dailyCap,
    int? muteHours,
  }) async {
    calls.add({
      if (dailyFortune != null) 'dailyFortune': dailyFortune,
      if (streakReminder != null) 'streakReminder': streakReminder,
      if (weeklySummary != null) 'weeklySummary': weeklySummary,
      if (quietFromHour != null) 'quietFromHour': quietFromHour,
      if (quietToHour != null) 'quietToHour': quietToHour,
      if (dailyCap != null) 'dailyCap': dailyCap,
      if (muteHours != null) 'muteHours': muteHours,
    });
    if (refuse) {
      return const ResultFailure(
        AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout'),
      );
    }
    stored = NotificationPreferences(
      dailyFortune: dailyFortune ?? stored.dailyFortune,
      streakReminder: streakReminder ?? stored.streakReminder,
      weeklySummary: weeklySummary ?? stored.weeklySummary,
      quietFromHour: quietFromHour ?? stored.quietFromHour,
      quietToHour: quietToHour ?? stored.quietToHour,
      dailyCap: dailyCap ?? stored.dailyCap,
      mutedUntil: muteHours == null
          ? stored.mutedUntil
          : muteHours > 0
              ? DateTime.now().add(Duration(hours: muteHours))
              : null,
    );
    return Success(stored);
  }
}

Widget host(FakeNotificationRepo repo) {
  return ProviderScope(
    overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: SingleChildScrollView(child: NotificationSettingsCard()),
      ),
    ),
  );
}

/// Every control on this card is a limit, and a limit that lies is worse than
/// no control at all — so a refused change must never move a switch.
void main() {
  testWidgets('shows the quiet hours it will actually respect', (tester) async {
    await tester.pumpWidget(host(FakeNotificationRepo()));
    await tester.pumpAndSettle();

    expect(find.text('یادآوری‌ها'), findsOneWidget);
    expect(find.textContaining('بین ۲۲:۰۰ و ۸:۰۰'), findsOneWidget);
  });

  testWidgets('a switch sends only the field it changed', (tester) async {
    final repo = FakeNotificationRepo();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('نگاهی به هفته‌ای که گذشت'));
    await tester.pumpAndSettle();

    expect(repo.calls, [
      {'weeklySummary': true},
    ]);
  });

  testWidgets('a refused change leaves the switch where it was', (
    tester,
  ) async {
    final repo = FakeNotificationRepo()..refuse = true;
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    final before = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'فال امروز'),
    );
    expect(before.value, isTrue);

    await tester.tap(find.text('فال امروز'));
    await tester.pumpAndSettle();

    final after = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'فال امروز'),
    );
    expect(after.value, isTrue);
  });

  testWidgets('a week of silence is one tap, and so is undoing it', (
    tester,
  ) async {
    final repo = FakeNotificationRepo();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('یک هفته چیزی نفرست'));
    await tester.pumpAndSettle();

    expect(repo.calls.last, {'muteHours': 168});
    expect(find.text('تا وقتی خودت بخواهی، پیامی نمی‌فرستیم.'), findsOneWidget);
    expect(find.text('باز هم خبرم بده'), findsOneWidget);

    await tester.tap(find.text('باز هم خبرم بده'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, {'muteHours': 0});
  });

  testWidgets('says nothing at all until the settings are known', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationControllerProvider.overrideWith(_Unknown.new),
        ],
        child: MaterialApp(
          locale: SupportedLocales.fa,
          supportedLocales: SupportedLocales.all,
          localizationsDelegates: SupportedLocales.delegates,
          theme: AppTheme.dark(),
          home: const Scaffold(body: NotificationSettingsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('یادآوری‌ها'), findsNothing);
  });
}

/// Settings that never arrive — an unreachable server, told honestly.
class _Unknown extends NotificationController {
  @override
  Future<NotificationPreferences?> build() async => null;
}
