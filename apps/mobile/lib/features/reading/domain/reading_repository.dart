import '../../../core/result/result.dart';
import '../../fortunes/domain/fal_input.dart';
import 'reading.dart';

/// Contract the application layer depends on — never the implementation.
abstract interface class ReadingRepository {
  /// [idempotencyKey] makes retries replay-safe (the backend returns the same
  /// reading). [adEntitlementId] is the one-time rewarded-ad unlock when the
  /// user earned access by watching an ad.
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
    String? adEntitlementId,
  });
}
