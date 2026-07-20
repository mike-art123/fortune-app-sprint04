import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../reading/domain/reading.dart';
import '../data/history_repository_impl.dart';
import '../domain/history_repository.dart';

/// Explicit lifecycle for the history surface — no boolean soup.
sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<Reading> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  HistoryLoaded copyWith({
    List<Reading>? items,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) =>
      HistoryLoaded(
        items: items ?? this.items,
        nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

final class HistoryFailed extends HistoryState {
  const HistoryFailed(this.failure);
  final AppFailure failure;
}

/// Drives the history list: first page on build, calm cursor pagination after.
class HistoryController extends AutoDisposeNotifier<HistoryState> {
  @override
  HistoryState build() {
    _loadFirstPage();
    return const HistoryLoading();
  }

  Future<void> _loadFirstPage() async {
    final result = await ref.read(historyRepositoryProvider).list();
    state = result.fold(
      onSuccess: (page) => HistoryLoaded(items: page.items, nextCursor: page.nextCursor),
      onFailure: HistoryFailed.new,
    );
  }

  Future<void> retry() async {
    state = const HistoryLoading();
    await _loadFirstPage();
  }

  /// Appends the next page. A failure here keeps what the user already has —
  /// losing a loaded list over a pagination hiccup would be needlessly harsh.
  Future<void> loadMore() async {
    final current = state;
    if (current is! HistoryLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = current.copyWith(isLoadingMore: true);
    final result = await ref.read(historyRepositoryProvider).list(cursor: current.nextCursor);

    state = result.fold(
      onSuccess: (page) => HistoryLoaded(
        items: [...current.items, ...page.items],
        nextCursor: page.nextCursor,
      ),
      onFailure: (_) => current.copyWith(isLoadingMore: false),
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(apiClientProvider));
});

final historyControllerProvider = NotifierProvider.autoDispose<HistoryController, HistoryState>(
  HistoryController.new,
);

/// One reading by id — powers cold deep links into the reading page.
final readingByIdProvider = FutureProvider.autoDispose.family<Reading, String>((
  ref,
  id,
) async {
  final result = await ref.watch(historyRepositoryProvider).byId(id);
  return result.fold(
    onSuccess: (reading) => reading,
    onFailure: (failure) => throw failure,
  );
});
