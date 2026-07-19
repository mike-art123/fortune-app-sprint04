import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/errors/error_mapper.dart';

void main() {
  final options = RequestOptions(path: '/x');

  test('connection timeout maps to timeout', () {
    final f = ErrorMapper.fromDio(
      DioException(requestOptions: options, type: DioExceptionType.connectionTimeout),
    );
    expect(f.kind, FailureKind.timeout);
  });

  test('401 maps to unauthorized', () {
    final f = ErrorMapper.fromDio(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: options, statusCode: 401),
      ),
    );
    expect(f.kind, FailureKind.unauthorized);
  });

  test('envelope INSUFFICIENT_COINS maps to its own kind (Sprint 04)', () {
    final f = ErrorMapper.fromEnvelope('INSUFFICIENT_COINS', 'no balance', 'req-1');
    expect(f.kind, FailureKind.insufficientCoins);
    expect(f.requestId, 'req-1');
    expect(f.isRetryable, isFalse);
  });

  test('Sprint 04 backend codes map onto the failure contract', () {
    expect(
      ErrorMapper.fromEnvelope('VALIDATION_FAILED', null, null).kind,
      FailureKind.validation,
    );
    expect(
      ErrorMapper.fromEnvelope('SUBSCRIPTION_REQUIRED', null, null).kind,
      FailureKind.subscriptionRequired,
    );
    expect(
      ErrorMapper.fromEnvelope('READING_FAILED', null, null).kind,
      FailureKind.server,
    );
    expect(
      ErrorMapper.fromEnvelope('CONFLICT', null, null).kind,
      FailureKind.conflict,
    );
  });

  test('every kind resolves a message key', () {
    for (final kind in FailureKind.values) {
      expect(ErrorMapper.messageKeyFor(kind), isNotEmpty);
    }
  });
}
