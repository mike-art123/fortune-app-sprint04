/// Crash reporting abstraction (doc 51 §28). Disabled in development unless
/// explicitly enabled. Must never block startup on failure.
abstract interface class CrashReportingService {
  Future<void> recordError(Object error, StackTrace? stackTrace, {bool fatal});
  Future<void> setContext(String key, Object? value);
  Future<void> breadcrumb(String message);
}

class NoopCrashReportingService implements CrashReportingService {
  const NoopCrashReportingService();
  @override
  Future<void> recordError(Object error, StackTrace? stackTrace, {bool fatal = false}) async {}
  @override
  Future<void> setContext(String key, Object? value) async {}
  @override
  Future<void> breadcrumb(String message) async {}
}
