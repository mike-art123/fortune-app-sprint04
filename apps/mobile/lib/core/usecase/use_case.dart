import '../result/result.dart';

/// Contract for synchronous use cases.
abstract interface class UseCase<Input, Output> {
  Result<Output> call(Input input);
}
