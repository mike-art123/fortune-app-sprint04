import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/history/application/history_controller.dart';
import 'package:fortune_app/features/history/domain/history_repository.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';

Reading _reading(String id) => Reading(
      id: id,
      fortuneId: 'hafez',
      title: 'عنوان $id',
      text: 'متنِ خوانش',
      createdAt: DateTime(2026, 1, 7),
    );

class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository(this._pages);

  /// cursor(null for first) → result
  final Map<String?, Result<ReadingListPage>> _pages;
  final List<String?> requestedCursors = [];

  @override
  Future<Result<ReadingListPage>> list({String? cursor}) async {
    requestedCursors.add(cursor);
    return _pages[cursor] ??
        const ResultFailure(
          AppFailure(kind: FailureKind.unknown, messageKey: 'x'),
        );
  }

  @override
  Future<Result<Reading>> byId(String id) async => Success(_reading(id));
}

ProviderContainer _container(HistoryRepository repo) {
  final container = ProviderContainer(
    overrides: [historyRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the first page newest-first and exposes it', () async {
    final repo = _FakeHistoryRepository({
      null: Success(
        ReadingListPage(
          items: [_reading('c2'), _reading('c1')],
          nextCursor: null,
        ),
      ),
    });
    final container = _container(repo);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    expect(sub.read(), isA<HistoryLoading>());
    await _settle();

    final state = sub.read();
    expect(state, isA<HistoryLoaded>());
    expect((state as HistoryLoaded).items.map((r) => r.id), ['c2', 'c1']);
    expect(state.hasMore, isFalse);
  });

  test('surfaces a typed failure and recovers on retry', () async {
    final failing = _FakeHistoryRepository({});
    final container = _container(failing);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    await _settle();
    expect(sub.read(), isA<HistoryFailed>());

    failing._pages[null] = Success(
      ReadingListPage(items: [_reading('c1')], nextCursor: null),
    );
    await container.read(historyControllerProvider.notifier).retry();

    expect(sub.read(), isA<HistoryLoaded>());
  });

  test('empty page is a loaded state, not an error', () async {
    final repo = _FakeHistoryRepository({
      null: const Success(ReadingListPage(items: [], nextCursor: null)),
    });
    final container = _container(repo);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    await _settle();

    final state = sub.read();
    expect(state, isA<HistoryLoaded>());
    expect((state as HistoryLoaded).items, isEmpty);
  });

  test('loadMore appends the next page using the server cursor', () async {
    final repo = _FakeHistoryRepository({
      null: Success(
        ReadingListPage(items: [_reading('c3')], nextCursor: 'cur-1'),
      ),
      'cur-1': Success(
        ReadingListPage(items: [_reading('c2')], nextCursor: null),
      ),
    });
    final container = _container(repo);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    await _settle();
    await container.read(historyControllerProvider.notifier).loadMore();

    final state = sub.read() as HistoryLoaded;
    expect(state.items.map((r) => r.id), ['c3', 'c2']);
    expect(state.hasMore, isFalse);
    expect(repo.requestedCursors, [null, 'cur-1']);
  });

  test('a failed loadMore keeps the already-loaded items', () async {
    final repo = _FakeHistoryRepository({
      null: Success(
        ReadingListPage(items: [_reading('c3')], nextCursor: 'cur-1'),
      ),
      // no entry for 'cur-1' → failure
    });
    final container = _container(repo);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    await _settle();
    await container.read(historyControllerProvider.notifier).loadMore();

    final state = sub.read() as HistoryLoaded;
    expect(state.items.map((r) => r.id), ['c3']);
    expect(state.isLoadingMore, isFalse);
  });

  test('loadMore is a no-op when there is no cursor', () async {
    final repo = _FakeHistoryRepository({
      null: Success(ReadingListPage(items: [_reading('c1')], nextCursor: null)),
    });
    final container = _container(repo);

    final sub = container.listen(historyControllerProvider, (_, __) {});
    await _settle();
    await container.read(historyControllerProvider.notifier).loadMore();

    expect(repo.requestedCursors, [null]);
    expect(sub.read(), isA<HistoryLoaded>());
  });
}
