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
