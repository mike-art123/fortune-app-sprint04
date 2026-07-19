import '../../../core/result/result.dart';
import '../../fortunes/domain/fal_input.dart';
import 'reading.dart';

/// Contract the application layer depends on — never the implementation.
abstract interface class ReadingRepository {
  /// Sprint 04: [idempotencyKey] makes retries charge-safe — the backend
  /// replays the same reading instead of debiting twice.
  Future<Result<Reading>> create(FalInput input, {String? idempotencyKey});
}
