import '../../../core/result/result.dart';
import '../../reading/domain/reading.dart';

/// One page of past readings, newest first.
class ReadingListPage {
  const ReadingListPage({required this.items, required this.nextCursor});

  final List<Reading> items;

  /// Opaque server cursor; null on the last page.
  final String? nextCursor;
}

/// Contract the application layer depends on — never the implementation.
abstract interface class HistoryRepository {
  Future<Result<ReadingListPage>> list({String? cursor});
  Future<Result<Reading>> byId(String id);

  /// Permanently delete every reading the caller owns. The int is how many
  /// rows went — the caller only cares that it succeeded.
  Future<Result<int>> clear();

  /// Permanently delete one reading the caller owns.
  Future<Result<int>> deleteById(String id);
}
