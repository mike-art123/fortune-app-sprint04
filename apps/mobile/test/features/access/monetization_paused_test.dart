import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/core/config/monetization_switch.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/access/application/access_flow_controller.dart';
import 'package:fortune_app/features/access/data/access_repository.dart';
import 'package:fortune_app/features/access/domain/access_models.dart';
import 'package:fortune_app/features/search/domain/search_intent.dart';

/// A repository that refuses to be used. If any of these ever runs while
/// monetization is paused, "paused" was a lie.
class _NeverAsked implements AccessRepository {
  @override
  Future<Result<AccessOptions>> accessOptions(String fortuneId) async =>
      throw StateError('access options were fetched while ads are paused');

  @override
  Future<Result<MediationSession>> createMediation(
    String fortuneId,
    String idempotencyKey,
  ) async =>
      throw StateError('an ad session was opened while ads are paused');

  @override
  Future<Result<MediationSession>> reportFailure(
    String sessionId,
    int attemptNumber,
    String reason,
  ) async =>
      throw StateError('an ad failure was reported while ads are paused');

  @override
  Future<Result<MediationStatus>> status(String sessionId) async =>
      throw StateError('an ad session was polled while ads are paused');

  @override
  Future<void> cancel(String sessionId) async =>
      throw StateError('an ad session was cancelled while ads are paused');
}

/// Ads and VIP are paused, not deleted — the model, the mediation chain and the
/// subscription flow are all still here and still tested. What this file proves
/// is the other half: while the switch is off, none of it is ever reached.
void main() {
  // A deliberate tripwire. When monetization comes back this fails, and it
  // fails pointing at every assumption in this file that must be revisited.
  test('ads and VIP are paused in this build', () {
    expect(kMonetizationEnabled, isFalse);
  });

  test('a ritual proceeds without asking anyone about access', () async {
    if (kMonetizationEnabled) return;

    final container = ProviderContainer(
      overrides: [accessRepositoryProvider.overrideWithValue(_NeverAsked())],
    );
    addTearDown(container.dispose);

    final flow = accessFlowControllerProvider('hafez');
    await container.read(flow.notifier).begin();

    expect(container.read(flow), isA<AccessProceed>());
  });

  test('nothing points a reader at a subscription that is not for sale', () {
    if (kMonetizationEnabled) return;

    expect(SearchIntents.forScreen('vip'), isNull);
    // The screens that remain are unaffected.
    expect(SearchIntents.forScreen('history'), isNotNull);
    expect(SearchIntents.forScreen('profile'), isNotNull);
    expect(SearchIntents.forScreen('fortunes'), isNotNull);
  });
}
