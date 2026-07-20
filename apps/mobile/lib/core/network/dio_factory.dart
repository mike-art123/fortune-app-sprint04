import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../persistence/secure_storage.dart';
import 'app_metadata_interceptor.dart';
import 'auth_interceptor.dart';
import 'locale_interceptor.dart';
import 'request_id_interceptor.dart';
import 'retry_interceptor.dart';

/// Builds the single configured Dio instance (doc 51 §21.1).
/// Features MUST NOT depend on this — they use [ApiClient].
abstract final class DioFactory {
  static Dio create({
    required AppConfig config,
    required TokenStore tokenStore,
    required String Function() localeCode,
    required Future<void> Function() onUnauthorized,
    required AppLogger logger,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.connectTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // We map status codes ourselves in ErrorMapper.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.addAll([
      RequestIdInterceptor(),
      LocaleInterceptor(localeCode),
      AppMetadataInterceptor(config),
      AuthInterceptor(tokenStore: tokenStore, onUnauthorized: onUnauthorized),
      RetryInterceptor(dio: dio),
    ]);

    if (config.verboseLogging) {
      // Headers/bodies are never logged by default — payloads carry personal
      // ritual input and tokens (doc 51 §26).
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            logger.debug('→ ${options.method} ${options.path}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            logger.debug(
              '← ${response.statusCode} ${response.requestOptions.path}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            logger.warning('✗ ${error.type.name} ${error.requestOptions.path}');
            handler.next(error);
          },
        ),
      );
    }

    return dio;
  }
}
