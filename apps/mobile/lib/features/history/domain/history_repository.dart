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
}
