import '../../../core/result/result.dart';
import '../../history/domain/history_repository.dart';

/// Contract for the saved-fortunes surface — never the implementation.
abstract interface class SavedRepository {
  /// One page of the caller's saved readings, newest-saved first.
  Future<Result<ReadingListPage>> list({String? cursor});

  /// Mark one reading as saved. The bool is the resulting saved state.
  Future<Result<bool>> save(String id);

  /// Remove one reading from saved. The bool is the resulting saved state.
  Future<Result<bool>> unsave(String id);
}
