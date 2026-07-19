import 'package:dio/dio.dart';
import '../constants/header_keys.dart';
import '../persistence/secure_storage.dart';

/// Injects the bearer token and exposes an unauthorized hook (doc 51 §24).
/// Full refresh-token rotation is implemented in the auth phase; the seam
/// exists here so no call site changes later.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Future<void> Function() onUnauthorized,
  })  : _tokens = tokenStore,
        _onUnauthorized = onUnauthorized;

  final TokenStore _tokens;
  final Future<void> Function() _onUnauthorized;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[HeaderKeys.authorization] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _onUnauthorized();
    }
    handler.next(err);
  }
}
