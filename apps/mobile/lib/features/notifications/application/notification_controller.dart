import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification_preferences.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);

/// The reader's notification settings (scope §7).
///
/// Null means "not known yet, or not reachable" — the screen then shows nothing
/// rather than a wrong switch position. A failed change leaves the previous
/// state exactly as it was, so a toggle never lies about what the server holds.
class NotificationController extends AsyncNotifier<NotificationPreferences?> {
  @override
  Future<NotificationPreferences?> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    final result = await repo.fetch();
    return result.fold(onSuccess: (value) => value, onFailure: (_) => null);
  }

  Future<void> _apply(
    Future<Result<NotificationPreferences>> Function(NotificationRepository)
        call,
  ) async {
    final repo = ref.read(notificationRepositoryProvider);
    final saved = (await call(repo)).valueOrNull;
    // Keep what we had: a failed save must never move a switch.
    if (saved != null) state = AsyncData(saved);
  }

  Future<void> setDailyFortune(bool value) =>
      _apply((repo) => repo.update(dailyFortune: value));

  Future<void> setStreakReminder(bool value) =>
      _apply((repo) => repo.update(streakReminder: value));

  Future<void> setWeeklySummary(bool value) =>
      _apply((repo) => repo.update(weeklySummary: value));

  Future<void> setQuietHours({required int from, required int to}) =>
      _apply((repo) => repo.update(quietFromHour: from, quietToHour: to));

  /// «فعلاً چیزی نفرست» — and it ends by itself. Zero lifts it.
  Future<void> mute(int hours) =>
      _apply((repo) => repo.update(muteHours: hours));
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationPreferences?>(
  NotificationController.new,
);
