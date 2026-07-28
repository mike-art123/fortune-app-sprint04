import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/result/result.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../reading/domain/reading.dart';
import '../data/saved_repository_impl.dart';
import '../domain/saved_repository.dart';

/// Explicit lifecycle for the saved surface — no boolean soup.
sealed class SavedState {
  const SavedState();
}

final class SavedLoading extends SavedState {
  const SavedLoading();
}

final class SavedLoaded extends SavedState {
  const SavedLoaded(this.items);
  final List<Reading> items;
}

final class SavedFailed extends SavedState {
  const SavedFailed(this.failure);
  final AppFailure failure;
}

/// Drives the saved-fortunes list, with an in-place unsave.
class SavedController extends AutoDisposeNotifier<SavedState> {
  @override
  SavedState build() {
    _load();
    return const SavedLoading();
  }

  Future<void> _load() async {
    final result = await ref.read(savedRepositoryProvider).list();
    state = result.fold(
      onSuccess: (page) => SavedLoaded(page.items),
      onFailure: SavedFailed.new,
    );
  }

  Future<void> retry() async {
    state = const SavedLoading();
    await _load();
  }

  /// Removes one reading from saved. On success it leaves the list; a failure
  /// keeps it exactly where it was, so a network blip never looks like loss.
  Future<bool> unsave(String id) async {
    final current = state;
    if (current is! SavedLoaded) return false;
    final result = await ref.read(savedRepositoryProvider).unsave(id);
    if (result is Success<bool>) {
      state = SavedLoaded(
        current.items.where((r) => r.id != id).toList(growable: false),
      );
      return true;
    }
    return false;
  }
}

final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  return SavedRepositoryImpl(ref.watch(apiClientProvider));
});

final savedControllerProvider =
    NotifierProvider.autoDispose<SavedController, SavedState>(
  SavedController.new,
);
