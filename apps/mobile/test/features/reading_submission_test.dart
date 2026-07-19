import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/errors/failure_message_resolver.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/fortunes/domain/fal_input.dart';
import 'package:fortune_app/features/reading/application/reading_submission_controller.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/domain/reading_repository.dart';

class _FakeRepo implements ReadingRepository {
  _FakeRepo(this.result);
  Result<Reading> result;
  int calls = 0;
  final List<String?> keys = [];

  @override
  Future<Result<Reading>> create(FalInput input, {String? idempotencyKey}) async {
    calls++;
    keys.add(idempotencyKey);
    return result;
  }
}

Reading _reading() => Reading(
      id: 'clx1',
      fortuneId: 'hafez',
      title: 'پیامی از دیوان',
      text: 'متن',
      createdAt: DateTime(2026),
    );

void main() {
  test('success path: idle → inflight → succeeded', () async {
    final repo = _FakeRepo(Success(_reading()));
    final container = ProviderContainer(
      overrides: [readingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(readingSubmissionControllerProvider, (_, __) {});
    expect(sub.read(), isA<SubmissionIdle>());

    await container
        .read(readingSubmissionControllerProvider.notifier)
        .submit(const IntentionInput(fortuneId: 'hafez'));

    expect(sub.read(), isA<SubmissionSucceeded>());
    expect(repo.calls, 1);
  });

  test('failure path resolves a friendly Persian message', () async {
    const failure = AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout');
    final container = ProviderContainer(
      overrides: [
        readingRepositoryProvider.overrideWithValue(_FakeRepo(const ResultFailure(failure))),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(readingSubmissionControllerProvider, (_, __) {});
    await container
        .read(readingSubmissionControllerProvider.notifier)
        .submit(const IntentionInput(fortuneId: 'hafez'));

    final state = sub.read();
    expect(state, isA<SubmissionFailed>());
    final message = FailureMessageResolver.resolve((state as SubmissionFailed).failure);
    expect(message, contains('دوباره تلاش کن'));
  });

  test('double submit is guarded while in flight', () async {
    final repo = _FakeRepo(Success(_reading()));
    final container = ProviderContainer(
      overrides: [readingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(readingSubmissionControllerProvider, (_, __) {});

    final notifier = container.read(readingSubmissionControllerProvider.notifier);
    final first = notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    final second = notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    await Future.wait([first, second]);

    expect(repo.calls, 1);
    expect(sub.read(), isA<SubmissionSucceeded>());
  });

  test('every submission carries a well-formed Idempotency-Key (Sprint 04)', () async {
    final repo = _FakeRepo(Success(_reading()));
    final container = ProviderContainer(
      overrides: [readingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(readingSubmissionControllerProvider, (_, __) {});

    await container
        .read(readingSubmissionControllerProvider.notifier)
        .submit(const IntentionInput(fortuneId: 'hafez'));

    expect(repo.keys.single, isNotNull);
    expect(repo.keys.single, matches(RegExp(r'^[A-Za-z0-9_-]{8,128}$')));
  });

  test('a retry after a retryable failure reuses the SAME key — one charge slot',
      () async {
    const timeoutFailure =
        AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout');
    final repo = _FakeRepo(const ResultFailure(timeoutFailure));
    final container = ProviderContainer(
      overrides: [readingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(readingSubmissionControllerProvider, (_, __) {});
    final notifier = container.read(readingSubmissionControllerProvider.notifier);

    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    repo.result = Success(_reading());
    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));

    expect(repo.keys, hasLength(2));
    expect(repo.keys[0], repo.keys[1]);
  });

  test('after success or a definitive refusal, the next cycle gets a fresh key',
      () async {
    final repo = _FakeRepo(Success(_reading()));
    final container = ProviderContainer(
      overrides: [readingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(readingSubmissionControllerProvider, (_, __) {});
    final notifier = container.read(readingSubmissionControllerProvider.notifier);

    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    notifier.reset();
    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    expect(repo.keys[0], isNot(repo.keys[1]));

    // Definitive refusal (insufficient coins) also ends the cycle.
    repo.result = const ResultFailure(
      AppFailure(kind: FailureKind.insufficientCoins, messageKey: 'errorInsufficientCoins'),
    );
    notifier.reset();
    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    repo.result = Success(_reading());
    await notifier.submit(const IntentionInput(fortuneId: 'hafez'));
    expect(repo.keys[2], isNot(repo.keys[3]));
  });
}
