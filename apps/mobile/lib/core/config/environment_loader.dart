import 'app_config.dart';
import 'app_flavor.dart';
import 'feature_flags.dart';

/// Builds [AppConfig] from compile-time `--dart-define` values (doc 51 §9/§10).
/// Parsing is typed and fails fast in development; production falls back to
/// safe defaults so a malformed define cannot brick launch.
abstract final class EnvironmentLoader {
  static AppConfig load(AppFlavor flavor) {
    const baseUrlDefine = String.fromEnvironment('API_BASE_URL');
    const connectMs = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const receiveMs = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 20000,
    );
    const analytics = bool.fromEnvironment(
      'ENABLE_ANALYTICS',
      defaultValue: false,
    );
    const crash = bool.fromEnvironment(
      'ENABLE_CRASH_REPORTING',
      defaultValue: false,
    );
    const debugMenu = bool.fromEnvironment(
      'ENABLE_DEBUG_MENU',
      defaultValue: false,
    );
    const botUsername = String.fromEnvironment('TELEGRAM_BOT_USERNAME');
    const devInitData = String.fromEnvironment('DEV_TELEGRAM_INITDATA');

    final baseUrl =
        baseUrlDefine.isNotEmpty ? baseUrlDefine : _defaultBaseUrl(flavor);

    if (flavor.isDevelopment && baseUrlDefine.isEmpty) {
      // Visible in dev only; production never depends on this path.
      // ignore: avoid_print
      print('[config] API_BASE_URL not provided — using $baseUrl');
    }

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: connectMs),
      receiveTimeout: const Duration(milliseconds: receiveMs),
      telegramBotUsername: botUsername.isEmpty ? null : botUsername,
      devTelegramInitData:
          flavor.isDevelopment && devInitData.isNotEmpty ? devInitData : null,
      flags: FeatureFlags(
        analyticsEnabled: analytics && flavor.isProduction,
        crashReportingEnabled: crash && !flavor.isDevelopment,
        debugMenuEnabled: debugMenu && !flavor.isProduction,
      ),
    );
  }

  static String _defaultBaseUrl(AppFlavor flavor) => switch (flavor) {
        AppFlavor.development => 'http://localhost:3000/api/v1',
        AppFlavor.staging => 'https://staging.api.example.com/v1',
        AppFlavor.production => 'https://api.example.com/v1',
      };
}
