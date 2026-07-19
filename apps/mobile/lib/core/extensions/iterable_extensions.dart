extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  Iterable<R> mapIndexed<R>(R Function(int index, T item) mapper) sync* {
    var i = 0;
    for (final item in this) {
      yield mapper(i++, item);
    }
  }
}
