/// What this person agreed to hear from us, and when (scope §7).
///
/// Every field is a limit rather than a capability. The defaults match the
/// server's: one message a day at most, nothing between 22:00 and 08:00, and
/// the weekly look-back off until it is asked for.
class NotificationPreferences {
  const NotificationPreferences({
    this.dailyFortune = true,
    this.streakReminder = true,
    this.weeklySummary = false,
    this.quietFromHour = 22,
    this.quietToHour = 8,
    this.dailyCap = 1,
    this.mutedUntil,
  });

  final bool dailyFortune;
  final bool streakReminder;
  final bool weeklySummary;
  final int quietFromHour;
  final int quietToHour;
  final int dailyCap;

  /// When silence ends. Null means nothing is muted.
  final DateTime? mutedUntil;

  /// Whether messages are held right now. Read against a clock rather than
  /// stored, so a mute that has passed needs no cleanup anywhere.
  bool isMutedAt(DateTime now) =>
      mutedUntil != null && mutedUntil!.isAfter(now);

  /// True when every kind is switched off — the honest reading of "silent",
  /// which the screen should say plainly instead of showing three off toggles.
  bool get isSilent =>
      !dailyFortune && !streakReminder && !weeklySummary || dailyCap == 0;

  static NotificationPreferences fromJson(Map<String, dynamic> json) {
    final muted = json['mutedUntil'];
    return NotificationPreferences(
      dailyFortune: json['dailyFortune'] as bool? ?? true,
      streakReminder: json['streakReminder'] as bool? ?? true,
      weeklySummary: json['weeklySummary'] as bool? ?? false,
      quietFromHour: json['quietFromHour'] as int? ?? 22,
      quietToHour: json['quietToHour'] as int? ?? 8,
      dailyCap: json['dailyCap'] as int? ?? 1,
      mutedUntil: muted is String ? DateTime.tryParse(muted) : null,
    );
  }
}
