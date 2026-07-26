import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/notifications/domain/notification_preferences.dart';

/// What the server sends is data, not a promise. Anything missing falls back to
/// the same modest defaults the server itself uses.
void main() {
  test('reads a complete payload', () {
    const payload = <String, dynamic>{
      'dailyFortune': false,
      'streakReminder': true,
      'weeklySummary': true,
      'quietFromHour': 23,
      'quietToHour': 7,
      'dailyCap': 2,
      'mutedUntil': '2026-08-01T00:00:00.000Z',
    };
    final prefs = NotificationPreferences.fromJson(payload);

    expect(prefs.dailyFortune, isFalse);
    expect(prefs.weeklySummary, isTrue);
    expect(prefs.quietFromHour, 23);
    expect(prefs.dailyCap, 2);
    expect(prefs.mutedUntil, DateTime.utc(2026, 8, 1));
  });

  test('falls back to the modest defaults', () {
    final prefs = NotificationPreferences.fromJson(const {});

    expect(prefs.dailyFortune, isTrue);
    expect(prefs.streakReminder, isTrue);
    expect(prefs.weeklySummary, isFalse);
    expect(prefs.quietFromHour, 22);
    expect(prefs.quietToHour, 8);
    expect(prefs.dailyCap, 1);
    expect(prefs.mutedUntil, isNull);
  });

  test('an unparseable mute is no mute at all', () {
    final prefs = NotificationPreferences.fromJson(const {
      'mutedUntil': 'the day after tomorrow',
    });
    expect(prefs.mutedUntil, isNull);
    expect(prefs.isMutedAt(DateTime.now()), isFalse);
  });

  test('a mute is read against the clock, so a past one is already over', () {
    final past = NotificationPreferences(
      mutedUntil: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final future = NotificationPreferences(
      mutedUntil: DateTime.now().add(const Duration(hours: 1)),
    );

    expect(past.isMutedAt(DateTime.now()), isFalse);
    expect(future.isMutedAt(DateTime.now()), isTrue);
  });

  test('silence is either nothing switched on, or a cap of zero', () {
    const allOff = NotificationPreferences(
      dailyFortune: false,
      streakReminder: false,
      weeklySummary: false,
    );
    const capped = NotificationPreferences(dailyCap: 0);

    expect(allOff.isSilent, isTrue);
    expect(capped.isSilent, isTrue);
    expect(const NotificationPreferences().isSilent, isFalse);
  });
}
