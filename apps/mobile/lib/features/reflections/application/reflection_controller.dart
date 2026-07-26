import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/shared_providers.dart';
import '../data/reflection_repository.dart';
import '../domain/reflection.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>(
  (ref) => ReflectionRepository(ref.watch(apiClientProvider)),
);

/// The entry already written for one reading, or null when there is none.
final reflectionForReadingProvider =
    FutureProvider.family<Reflection?, String>((ref, readingId) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  final result = await repo.forReading(readingId);
  return result.fold(onSuccess: (value) => value, onFailure: (_) => null);
});

/// The line to sit under the note, for the feeling currently chosen.
final reflectionLineProvider =
    FutureProvider.family<ReflectionLine?, Feeling>((ref, feeling) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  final result = await repo.line(feeling);
  return result.fold(onSuccess: (value) => value, onFailure: (_) => null);
});

/// The journal, newest first (scope §8).
///
/// A failure resolves to an empty page rather than an error: the diary is the
/// person's own, and an unreachable server is not something to scold them with.
class JournalController extends AsyncNotifier<List<Reflection>> {
  @override
  Future<List<Reflection>> build() async {
    final repo = ref.watch(reflectionRepositoryProvider);
    final result = await repo.list();
    return result.fold(
      onSuccess: (page) => page.items,
      onFailure: (_) => const <Reflection>[],
    );
  }

  /// Writes or rewrites, then refreshes the timeline so both surfaces agree.
  Future<bool> save({
    required String? readingId,
    required Feeling feeling,
    required String note,
  }) async {
    final repo = ref.read(reflectionRepositoryProvider);
    final result = await repo.save(
      readingId: readingId,
      feeling: feeling,
      note: note,
    );
    final saved = result.valueOrNull;
    if (saved == null) return false;

    if (readingId != null) {
      ref.invalidate(reflectionForReadingProvider(readingId));
    }
    ref.invalidateSelf();
    return true;
  }

  Future<void> remove(String id) async {
    final repo = ref.read(reflectionRepositoryProvider);
    final result = await repo.remove(id);
    if (result.isSuccess) ref.invalidateSelf();
  }
}

final journalControllerProvider =
    AsyncNotifierProvider<JournalController, List<Reflection>>(
  JournalController.new,
);

/// What the journal is filtered down to, if anything. A plain choice, kept
/// where the chips and the list can both see it.
final journalFilterProvider = StateProvider<Feeling?>((ref) => null);

/// The entries actually on screen: the timeline, narrowed by the chosen word.
final visibleJournalProvider = Provider<List<Reflection>>((ref) {
  final all = ref.watch(journalControllerProvider).valueOrNull ?? const [];
  final filter = ref.watch(journalFilterProvider);
  if (filter == null) return all;
  return all.where((entry) => entry.feeling == filter).toList(growable: false);
});
