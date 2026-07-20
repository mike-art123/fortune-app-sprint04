import 'package:dio/dio.dart';
import '../errors/error_mapper.dart';
import '../result/result.dart';
import 'api_response.dart';

/// The only networking surface features may depend on (doc 51 §4.2, §53).
/// Unwraps the backend envelope and returns typed [Result]s — never raw Dio.
class ApiClient {
  const ApiClient(this._dio);
  final Dio _dio;

  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.get<dynamic>(
          path,
          queryParameters: query,
          cancelToken: cancelToken,
          options: headers == null ? null : Options(headers: headers),
        ),
      );

  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.post<dynamic>(
          path,
          data: body,
          cancelToken: cancelToken,
          options: headers == null ? null : Options(headers: headers),
        ),
      );

  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.patch<dynamic>(path, data: body, cancelToken: cancelToken),
      );

  Future<Result<Map<String, dynamic>>> delete(
    String path, {
    CancelToken? cancelToken,
  }) =>
      _request(() => _dio.delete<dynamic>(path, cancelToken: cancelToken));

  Future<Result<Map<String, dynamic>>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return ResultFailure(
          ErrorMapper.parsing('Expected JSON object, got ${raw.runtimeType}'),
        );
      }
      final envelope = ApiEnvelope.fromJson(raw);
      if (!envelope.success) {
        return ResultFailure(
          ErrorMapper.fromEnvelope(
            envelope.errorCode,
            envelope.errorMessage,
            envelope.requestId,
          ),
        );
      }
      return Success(envelope.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return ResultFailure(ErrorMapper.fromDio(e));
    } catch (e) {
      return ResultFailure(ErrorMapper.parsing(e));
    }
  }
}
