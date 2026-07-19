import 'package:dio/dio.dart';
import '../constants/header_keys.dart';

/// Sends the active locale so the backend can localise its own content.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._localeCode);
  final String Function() _localeCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[HeaderKeys.acceptLanguage] = _localeCode();
    handler.next(options);
  }
}
