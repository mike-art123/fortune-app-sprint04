import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/shared_providers.dart';
import '../data/history_summary_repository.dart';
import '../domain/history_summary.dart';

final historySummaryRepositoryProvider = Provider<HistorySummaryRepository>(
  (ref) => HistorySummaryRepository(ref.watch(apiClientProvider)),
);

/// Which window the journal is currently describing. A plain choice, kept
/// where both the chips and the card can see it.
final summaryRangeProvider = StateProvider<SummaryRange>(
  (ref) => SummaryRange.last30,
);

/// The summary for the chosen window (scope §6).
///
/// A failure resolves to null rather than an error: the journal itself is the
/// point of the page, and it is already on screen. Nothing here can keep a
/// reader from their own readings.
final historySummaryProvider = FutureProvider<HistorySummary?>((ref) async {
  final range = ref.watch(summaryRangeProvider);
  final repo = ref.watch(historySummaryRepositoryProvider);
  final result = await repo.forRange(range);
  return result.fold(onSuccess: (value) => value, onFailure: (_) => null);
});
