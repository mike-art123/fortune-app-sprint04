import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../fortunes/domain/fal_input.dart';
import '../data/reading_repository_impl.dart';
import '../domain/reading.dart';
import '../domain/reading_repository.dart';

/// Explicit submission lifecycle — no boolean soup (doc 51 §4.3).
sealed class ReadingSubmissionState {
  const ReadingSubmissionState();
}

final class SubmissionIdle extends ReadingSubmissionState {
  const SubmissionIdle();
}

final class SubmissionInFlight extends ReadingSubmissionState {
  const SubmissionInFlight();
}

final class SubmissionSucceeded extends ReadingSubmissionState {
  const SubmissionSucceeded(this.reading);
  final Reading reading;
}

final class SubmissionFailed extends ReadingSubmissionState {
  const SubmissionFailed(this.failure);
  final AppFailure failure;
}

/// Drives one ritual submission. Two charge-safety layers live here
/// (Sprint 04): the in-flight guard blocks double submits, and one
/// Idempotency-Key per attempt-cycle makes ambiguous retries safe — a retry
/// after a timeout replays the same reading instead of paying twice.
class ReadingSubmissionController extends AutoDisposeNotifier<ReadingSubmissionState> {
  /// Kept across retryable failures, discarded on success/reset/final failure.
  String? _pendingIdempotencyKey;

  @override
  ReadingSubmissionState build() => const SubmissionIdle();

  Future<void> submit(FalInput input) async {
    if (state is SubmissionInFlight) return;
    final key = _pendingIdempotencyKey ??= const Uuid().v4();
    state = const SubmissionInFlight();

    final result = await ref.read(readingRepositoryProvider).create(input, idempotencyKey: key);
    state = result.fold(
      onSuccess: (reading) {
        _pendingIdempotencyKey = null;
        return SubmissionSucceeded(reading);
      },
      onFailure: (failure) {
        // A retryable failure keeps the key: the retry lands on the same
        // charge slot. A definitive refusal starts a fresh cycle.
        if (!failure.isRetryable) _pendingIdempotencyKey = null;
        return SubmissionFailed(failure);
      },
    );
  }

  /// Called after navigation or when the user edits the offering again.
  void reset() {
    _pendingIdempotencyKey = null;
    state = const SubmissionIdle();
  }
}

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepositoryImpl(ref.watch(apiClientProvider));
});

final readingSubmissionControllerProvider =
    NotifierProvider.autoDispose<ReadingSubmissionController, ReadingSubmissionState>(
        ReadingSubmissionController.new);
