import 'log_event.dart';

/// Logging abstraction (doc 51 §26). Implementations MUST redact secrets and
/// personal content: tokens, ritual input, reading text, Telegram payloads.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
  void debug(String message);
  void info(String message);
  void warning(String message, {Object? error});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// Console logger for development. Production builds should stay restrained.
class ConsoleLogger implements AppLogger {
  const ConsoleLogger({this.verbose = true});
  final bool verbose;

  static final _redactPatterns = <RegExp>[
    RegExp(r'(Bearer\s+)[A-Za-z0-9._\-]+'),
    RegExp(r'("(?:access|refresh)Token"\s*:\s*")[^"]*'),
    RegExp(r'(initData=)[^&\s]*'),
  ];

  static String redact(String input) {
    var out = input;
    for (final p in _redactPatterns) {
      out = out.replaceAllMapped(p, (m) => '${m.group(1)}[redacted]');
    }
    return out;
  }

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!verbose && (level == LogLevel.debug || level == LogLevel.info)) return;
    final line = '[${level.name}] ${redact(message)}';
    // ignore: avoid_print
    print(error == null ? line : '$line | ${redact(error.toString())}');
  }

  @override
  void debug(String message) => log(LogLevel.debug, message);
  @override
  void info(String message) => log(LogLevel.info, message);
  @override
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}
