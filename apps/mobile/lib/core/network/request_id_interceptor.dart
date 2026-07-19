import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../constants/header_keys.dart';

/// Attaches a correlation id to every request so client and server logs match.
class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor([Uuid? uuid]) : _uuid = uuid ?? const Uuid();
  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[HeaderKeys.requestId] = _uuid.v4();
    handler.next(options);
  }
}
