import 'package:dio/dio.dart';

/// Conservative retry policy (doc 51 §21.3).
/// Retries ONLY idempotent GETs on transient transport/5xx errors.
/// Never retries purchases, coin debits, reading generation, or auth — a silent
/// duplicate there costs the user money or trust.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxAttempts = 2,
    this.backoff = const Duration(milliseconds: 400),
  }) : _dio = dio;

  final Dio _dio;
  final int maxAttempts;
  final Duration backoff;

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) return handler.next(err);

    final attempt = (err.requestOptions.extra[_attemptKey] as int? ?? 0) + 1;
    if (attempt > maxAttempts) return handler.next(err);

    await Future<void>.delayed(backoff * attempt);
    final options = err.requestOptions..extra[_attemptKey] = attempt;

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET')
      return false; // side-effecting requests are never retried
    final status = err.response?.statusCode;
    final transient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
    final serverSide = status != null && status >= 500 && status != 501;
    return transient || serverSide;
  }
}
