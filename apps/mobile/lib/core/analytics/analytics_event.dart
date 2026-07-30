/// Typed analytics events (doc 51 §27). Never carry personal content:
/// no ritual intention text, no reading text, no names.
sealed class AnalyticsEvent {
  const AnalyticsEvent();
  String get name;
  Map<String, Object?> get parameters => const {};
}

class AppStarted extends AnalyticsEvent {
  const AppStarted();
  @override
  String get name => 'app_started';
}

class BootstrapFailed extends AnalyticsEvent {
  const BootstrapFailed(this.reason);
  final String reason;
  @override
  String get name => 'bootstrap_failed';
  @override
  Map<String, Object?> get parameters => {'reason': reason};
}

class RouteOpened extends AnalyticsEvent {
  const RouteOpened(this.routeName);
  final String routeName;
  @override
  String get name => 'route_opened';
  @override
  Map<String, Object?> get parameters => {'route': routeName};
}

class LocaleChanged extends AnalyticsEvent {
  const LocaleChanged(this.localeCode);
  final String localeCode;
  @override
  String get name => 'locale_changed';
  @override
  Map<String, Object?> get parameters => {'locale': localeCode};
}

class ThemeChanged extends AnalyticsEvent {
  const ThemeChanged(this.mode);
  final String mode;
  @override
  String get name => 'theme_changed';
  @override
  Map<String, Object?> get parameters => {'mode': mode};
}

/// ── Rewarded-ad lifecycle (ids and reasons only; never content) ──

class RewardRequested extends AnalyticsEvent {
  const RewardRequested(this.fortuneId);
  final String fortuneId;
  @override
  String get name => 'reward_requested';
  @override
  Map<String, Object?> get parameters => {'fortune': fortuneId};
}

class RewardShown extends AnalyticsEvent {
  const RewardShown(this.provider);
  final String provider;
  @override
  String get name => 'reward_shown';
  @override
  Map<String, Object?> get parameters => {'provider': provider};
}

class RewardCompleted extends AnalyticsEvent {
  const RewardCompleted(this.provider);
  final String provider;
  @override
  String get name => 'reward_completed';
  @override
  Map<String, Object?> get parameters => {'provider': provider};
}

/// The user closed the ad on purpose — an answer, not a failure.
class RewardSkipped extends AnalyticsEvent {
  const RewardSkipped(this.provider);
  final String provider;
  @override
  String get name => 'reward_skipped';
  @override
  Map<String, Object?> get parameters => {'provider': provider};
}

class RewardFailed extends AnalyticsEvent {
  const RewardFailed(this.provider, this.reason);
  final String provider;
  final String reason;
  @override
  String get name => 'reward_failed';
  @override
  Map<String, Object?> get parameters =>
      {'provider': provider, 'reason': reason};
}

class FortuneUnlocked extends AnalyticsEvent {
  const FortuneUnlocked(this.method);
  final String method;
  @override
  String get name => 'fortune_unlocked';
  @override
  Map<String, Object?> get parameters => {'method': method};
}
