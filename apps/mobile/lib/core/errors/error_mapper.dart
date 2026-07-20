import 'package:dio/dio.dart';
import 'app_failure.dart';

/// Single place where infrastructure errors become typed failures (doc 51 §23).
/// Backend copy is never surfaced verbatim — we resolve our own message key.
abstract final class ErrorMapper {
  static AppFailure fromDio(DioException e) {
    final requestId = e.response?.headers.value('X-Request-Id');
    final status = e.response?.statusCode;

    final kind = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        FailureKind.timeout,
      DioExceptionType.connectionError => FailureKind.networkUnavailable,
      DioExceptionType.cancel => FailureKind.unknown,
      DioExceptionType.badResponse => _fromStatus(status),
      _ => FailureKind.unknown,
    };

    return AppFailure(
      kind: kind,
      messageKey: messageKeyFor(kind),
      developerMessage: 'dio:${e.type.name} status:$status',
      requestId: requestId,
    );
  }

  static AppFailure fromEnvelope(
    String? code,
    String? devMessage,
    String? requestId,
  ) {
    final kind = switch (code) {
      'UNAUTHORIZED' => FailureKind.unauthorized,
      'FORBIDDEN' => FailureKind.forbidden,
      'NOT_FOUND' => FailureKind.notFound,
      'VALIDATION_FAILED' || 'INVALID_INPUT' => FailureKind.validation,
      'DUPLICATE_REQUEST' || 'CONFLICT' => FailureKind.conflict,
      'RATE_LIMIT' => FailureKind.rateLimited,
      'AI_TIMEOUT' || 'REQUEST_TIMEOUT' => FailureKind.timeout,
      'INSUFFICIENT_COINS' => FailureKind.insufficientCoins,
      'SUBSCRIPTION_REQUIRED' => FailureKind.subscriptionRequired,
      'READING_FAILED' => FailureKind.server,
      _ => FailureKind.server,
    };
    return AppFailure(
      kind: kind,
      messageKey: messageKeyFor(kind),
      developerMessage: 'code:$code msg:$devMessage',
      requestId: requestId,
    );
  }

  static AppFailure parsing(Object error) => AppFailure(
        kind: FailureKind.parsing,
        messageKey: messageKeyFor(FailureKind.parsing),
        developerMessage: error.toString(),
      );

  static FailureKind _fromStatus(int? status) => switch (status) {
        400 || 422 => FailureKind.validation,
        401 => FailureKind.unauthorized,
        402 => FailureKind.insufficientCoins,
        403 => FailureKind.forbidden,
        404 => FailureKind.notFound,
        409 => FailureKind.conflict,
        429 => FailureKind.rateLimited,
        _ => FailureKind.server,
      };

  static String messageKeyFor(FailureKind kind) => switch (kind) {
        FailureKind.networkUnavailable => 'errorNetworkUnavailable',
        FailureKind.timeout => 'errorTimeout',
        FailureKind.unauthorized || FailureKind.forbidden => 'errorUnauthorized',
        FailureKind.notFound => 'errorNotFound',
        FailureKind.validation => 'errorValidation',
        FailureKind.conflict => 'errorConflict',
        FailureKind.rateLimited => 'errorRateLimited',
        FailureKind.insufficientCoins => 'errorInsufficientCoins',
        FailureKind.subscriptionRequired => 'errorSubscriptionRequired',
        FailureKind.storage => 'errorStorage',
        FailureKind.parsing || FailureKind.server || FailureKind.unknown => 'errorGeneric',
      };
}
