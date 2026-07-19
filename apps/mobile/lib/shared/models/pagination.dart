/// Cursor pagination envelope shared across list features (doc 33).
class Paginated<T> {
  const Paginated({required this.items, this.nextCursor});
  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
