import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/next_fortunes.dart';

/// The reader's own past readings, reduced to (which fortune, when). A failure
/// is simply an empty history: a suggestion is a courtesy, never something to
/// apologise for.
final historyMomentsProvider = FutureProvider<List<ReadingMoment>>((ref) async {
  final page = await ref.watch(historyRepositoryProvider).list();
  return page.fold(
    onSuccess: (value) => value.items
        .map((r) => ReadingMoment(fortuneId: r.fortuneId, at: r.createdAt))
        .toList(growable: false),
    onFailure: (_) => const <ReadingMoment>[],
  );
});

/// Where to go after the reading with this fortune id (scope §4, §5).
///
/// Deliberately inert: it never waits for anything and never fails. Until the
/// profile is actually in hand the answer is empty, and when personalization is
/// switched off the history is not even asked for — no request, no suggestion,
/// no trace. A reading that opens before the app has settled simply ends the
/// way it always did.
typedef NextFortunesRequest = ({String fortuneId, Locale locale});

final nextFortunesProvider =
    Provider.family<List<NextFortune>, NextFortunesRequest>((
  ref,
  request,
) {
  final profile = ref.watch(profileControllerProvider).valueOrNull;
  if (profile == null || profile.personalizationOptOut) return const [];

  final history = ref.watch(historyMomentsProvider).valueOrNull;
  if (history == null) return const [];

  return nextFortunes(
    justRead: request.fortuneId,
    history: history,
    now: DateTime.now(),
    locale: request.locale,
  );
});
