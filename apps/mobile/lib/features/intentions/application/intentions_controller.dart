import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/result/result.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/intention_repository_impl.dart';
import '../domain/intention.dart';

/// Explicit lifecycle for the intentions surface — no boolean soup.
sealed class IntentionsState {
  const IntentionsState();
}

final class IntentionsLoading extends IntentionsState {
  const IntentionsLoading();
}

final class IntentionsLoaded extends IntentionsState {
  const IntentionsLoaded(this.items);
  final List<Intention> items;
}

final class IntentionsFailed extends IntentionsState {
  const IntentionsFailed(this.failure);
  final AppFailure failure;
}

/// Loads the caller's whispered intentions once, newest first.
class IntentionsController extends AutoDisposeNotifier<IntentionsState> {
  @override
  IntentionsState build() {
    _load();
    return const IntentionsLoading();
  }

  Future<void> _load() async {
    final result = await ref.read(intentionsRepositoryProvider).list();
    state = result.fold(
      onSuccess: IntentionsLoaded.new,
      onFailure: IntentionsFailed.new,
    );
  }

  Future<void> retry() async {
    state = const IntentionsLoading();
    await _load();
  }
}

final intentionsRepositoryProvider = Provider<IntentionsRepository>((ref) {
  return IntentionRepositoryImpl(ref.watch(apiClientProvider));
});

final intentionsControllerProvider =
    NotifierProvider.autoDispose<IntentionsController, IntentionsState>(
  IntentionsController.new,
);
