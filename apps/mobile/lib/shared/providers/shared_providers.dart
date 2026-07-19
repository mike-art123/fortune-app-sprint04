import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/config/app_config.dart';
import '../../core/crash_reporting/crash_reporting_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_factory.dart';
import '../../core/network/network_info.dart';
import '../../core/network/session_events.dart';
import '../../core/persistence/local_storage.dart';
import '../../core/persistence/secure_storage.dart';
import '../../core/persistence/storage_migrations.dart';
import '../../core/platform/telegram_platform_bridge.dart';
import '../../app/localization/locale_controller.dart';

/// Core infrastructure providers. Those that require async initialisation are
/// declared as `UnimplementedError` and overridden at bootstrap (doc 51 §46) —
/// this makes missing wiring fail loudly at startup instead of silently later.

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden at bootstrap');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden at bootstrap');
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  throw UnimplementedError('secureStorageProvider must be overridden at bootstrap');
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return ConsoleLogger(verbose: ref.watch(appConfigProvider).verboseLogging);
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // Vendor integration is out of scope for the foundation phase.
  return const NoopAnalyticsService();
});

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return const NoopCrashReportingService();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final storageMigrationsProvider = Provider<StorageMigrations>((ref) {
  return StorageMigrations(ref.watch(localStorageProvider));
});

final networkInfoProvider = Provider<NetworkInfo>((ref) => ConnectivityNetworkInfo());

/// 401 broadcast from the networking layer; the auth controller listens and
/// re-establishes the session (Sprint 04 / doc 53).
final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final telegramBridgeProvider = Provider<TelegramPlatformBridge>((ref) {
  // Non-Telegram targets degrade gracefully; the web bridge lands with auth.
  return const UnavailableTelegramBridge();
});

/// Internal — features must not read this. Use [apiClientProvider].
final _dioProvider = Provider<Dio>((ref) {
  return DioFactory.create(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    localeCode: () => ref.read(localeControllerProvider).languageCode,
    onUnauthorized: () async {
      // Sprint 04: the auth controller owns recovery — clear-and-relogin.
      ref.read(sessionEventsProvider).notifyUnauthorized();
    },
    logger: ref.watch(appLoggerProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(_dioProvider)));

