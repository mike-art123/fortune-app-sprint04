import '../errors/app_failure.dart';

/// Sealed result type used by repositories and use cases (doc 51 §23).
sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    final self = this;
    return self is Success<T>
        ? onSuccess(self.value)
        : onFailure((self as ResultFailure<T>).failure);
  }

  bool get isSuccess => this is Success<T>;
  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  AppFailure? get failureOrNull =>
      this is ResultFailure<T> ? (this as ResultFailure<T>).failure : null;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Named `ResultFailure` to avoid colliding with Flutter's `Failure` naming
/// and with [AppFailure] itself.
final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final AppFailure failure;
}
