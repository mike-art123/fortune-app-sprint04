import '../result/result.dart';

/// Contract for asynchronous use cases. Controllers depend on these, not on
/// repository implementations.
abstract interface class AsyncUseCase<Input, Output> {
  Future<Result<Output>> call(Input input);
}
