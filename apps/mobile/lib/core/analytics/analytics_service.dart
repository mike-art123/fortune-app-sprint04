import 'analytics_event.dart';

/// Vendor-free analytics interface (doc 51 §27).
abstract interface class AnalyticsService {
  Future<void> track(AnalyticsEvent event);
}

/// Default no-op implementation — analytics must never affect UX or startup.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();
  @override
  Future<void> track(AnalyticsEvent event) async {}
}
