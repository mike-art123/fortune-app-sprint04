import '../constants/app_constants.dart';
import 'app_flavor.dart';
import 'feature_flags.dart';

/// Immutable, typed application configuration (doc 51 §10).
/// No raw map access, no secrets — the Flutter client is untrusted (§33).
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.flags,
    this.telegramBotUsername,
    this.devTelegramInitData,
    this.appVersion = '0.1.0',
    this.buildNumber = '1',
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final FeatureFlags flags;
  final String? telegramBotUsername;

  /// Development/test seam (Sprint 04): raw initData injected via dart-define,
  /// honored ONLY in the development flavor. It is still fully verified by the
  /// backend — this bypasses Telegram's webview, never security.
  final String? devTelegramInitData;
  final String appVersion;
  final String buildNumber;

  String get defaultLocaleCode => AppConstants.defaultLocaleCode;
  bool get isProduction => flavor.isProduction;

  /// Verbose logging and body capture are development-only.
  bool get verboseLogging => flavor.isDevelopment;
}
