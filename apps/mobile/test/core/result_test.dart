import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';

void main() {
  group('Result', () {
    test('Success folds to the value', () {
      const Result<int> r = Success(42);
      expect(r.fold(onSuccess: (v) => v, onFailure: (_) => -1), 42);
      expect(r.isSuccess, isTrue);
      expect(r.valueOrNull, 42);
    });

    test('ResultFailure folds to the failure', () {
      const failure = AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout');
      const Result<int> r = ResultFailure(failure);
      expect(r.isSuccess, isFalse);
      expect(r.failureOrNull?.kind, FailureKind.timeout);
    });
  });

  group('AppFailure', () {
    test('transient kinds are retryable', () {
      const f = AppFailure(kind: FailureKind.networkUnavailable, messageKey: 'k');
      expect(f.isRetryable, isTrue);
    });

    test('validation is not retryable', () {
      const f = AppFailure(kind: FailureKind.validation, messageKey: 'k');
      expect(f.isRetryable, isFalse);
    });

    test('unauthorized requires reauth', () {
      const f = AppFailure(kind: FailureKind.unauthorized, messageKey: 'k');
      expect(f.requiresReauth, isTrue);
    });
  });
}
