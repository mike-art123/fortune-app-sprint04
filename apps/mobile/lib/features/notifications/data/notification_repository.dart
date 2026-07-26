import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/notification_preferences.dart';

/// Notification preferences surface (scope §7). The server owns the limits and
/// clamps them; this layer only moves JSON.
class NotificationRepository {
  const NotificationRepository(this._api);

  final ApiClient _api;

  Future<Result<NotificationPreferences>> fetch() async {
    final result = await _api.get('/notifications/preferences');
    return result.fold(onSuccess: _parse, onFailure: ResultFailure.new);
  }

  /// Sends only what changed. An omitted field is left exactly as it was.
  Future<Result<NotificationPreferences>> update({
    bool? dailyFortune,
    bool? streakReminder,
    bool? weeklySummary,
    int? quietFromHour,
    int? quietToHour,
    int? dailyCap,
    int? muteHours,
  }) async {
    final result = await _api.patch(
      '/notifications/preferences',
      body: {
        if (dailyFortune != null) 'dailyFortune': dailyFortune,
        if (streakReminder != null) 'streakReminder': streakReminder,
        if (weeklySummary != null) 'weeklySummary': weeklySummary,
        if (quietFromHour != null) 'quietFromHour': quietFromHour,
        if (quietToHour != null) 'quietToHour': quietToHour,
        if (dailyCap != null) 'dailyCap': dailyCap,
        if (muteHours != null) 'muteHours': muteHours,
      },
    );
    return result.fold(onSuccess: _parse, onFailure: ResultFailure.new);
  }

  Result<NotificationPreferences> _parse(Map<String, dynamic> data) {
    try {
      return Success(NotificationPreferences.fromJson(data));
    } catch (e) {
      return ResultFailure(ErrorMapper.parsing(e));
    }
  }
}
