import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/next_fortunes.dart';

/// Where to go after the reading with this fortune id (scope §4, §5).
///
/// Reads the person's own history and nothing else. When personalization is
/// switched off the answer is simply empty — no request, no suggestion, no
/// trace. A failure to load history is also empty: a suggestion is a courtesy,
/// never something to apologise for.
final nextFortunesProvider =
    FutureProvider.family<List<NextFortune>, String>((ref, fortuneId) async {
  final profile = await ref.watch(profileControllerProvider.future);
  if (profile?.personalizationOptOut ?? false) return const [];

  final page = await ref.watch(historyRepositoryProvider).list();
  final history = page.fold(
    onSuccess: (value) => value.items
        .map((r) => ReadingMoment(fortuneId: r.fortuneId, at: r.createdAt))
        .toList(growable: false),
    onFailure: (_) => const <ReadingMoment>[],
  );

  return nextFortunes(
    justRead: fortuneId,
    history: history,
    now: DateTime.now(),
  );
});
