import 'package:flutter/widgets.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_service.dart';

/// Reports route changes to analytics. Route names only — never parameters,
/// which may contain identifiers.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);
  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) _analytics.track(RouteOpened(name));
    super.didPush(route, previousRoute);
  }
}
