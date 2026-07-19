import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/header_keys.dart';
import '../platform/platform_info.dart';

/// Adds client version and platform metadata for support and diagnostics.
class AppMetadataInterceptor extends Interceptor {
  AppMetadataInterceptor(this._config);
  final AppConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[HeaderKeys.clientVersion] = '${_config.appVersion}+${_config.buildNumber}';
    options.headers[HeaderKeys.platform] = PlatformInfo.name;
    handler.next(options);
  }
}
