import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/platform/rewarded_ad_player.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/access_repository.dart';
import '../domain/access_models.dart';

/// Reasons that may fall through to the next provider automatically. A user
/// skip/close, a verification failure, the global daily limit and a cancel
/// never do — those stop the chain (spec).
const _fallbackReasons = {
  'no_fill',
  'ad_unavailable',
  'provider_frequency_cap',
  'load_timeout',
  'temporary_provider_error',
  'unsupported_region',
};

/// Explicit access-flow lifecycle for one fortune request.
sealed class AccessFlowState {
  const AccessFlowState();
}

final class AccessIdle extends AccessFlowState {
  const AccessIdle();
}

final class AccessChecking extends AccessFlowState {
  const AccessChecking();
}

/// Show the two-choice sheet (rewarded ad / VIP).
final class AccessSheet extends AccessFlowState {
  const AccessSheet(this.options);
  final AccessOptions options;
}

/// «در حال آماده‌سازی تبلیغ...» — mediation is running; no user action needed.
final class AccessPreparingAd extends AccessFlowState {
  const AccessPreparingAd();
}

/// The global BakhtNegar daily rewarded-ad limit is spent — VIP only.
final class AccessLimitReached extends AccessFlowState {
  const AccessLimitReached();
}

/// Every eligible provider failed — offer retry or VIP.
final class AccessAdsExhausted extends AccessFlowState {
  const AccessAdsExhausted();
}

/// Access granted: submit now (with the one-time unlock when ad-based).
final class AccessProceed extends AccessFlowState {
  const AccessProceed({this.adEntitlementId});
  final String? adEntitlementId;
}

final class AccessError extends AccessFlowState {
  const AccessError(this.failure);
  final AppFailure failure;
}

/// Orchestrates «گرفتن فال» access: backend decision first (VIP → free →
/// sheet), then — only when the user chooses the ad — the mediation loop.
/// Provider order, verification and the reward itself are all backend-owned;
/// this controller merely executes and reports.
class AccessFlowController
    extends AutoDisposeFamilyNotifier<AccessFlowState, String> {
  /// One key per pending request-cycle; rotated when a chain ends unrewarded
  /// so «تلاش دوباره» starts a fresh session instead of replaying a dead one.
  String? _idempotencyKey;

  AccessOptions? _lastOptions;

  String get _fortuneId => arg;

  @override
  AccessFlowState build(String arg) => const AccessIdle();

  /// Backend decision order: vip/free start immediately; otherwise the sheet.
  Future<void> begin() async {
    if (state is AccessChecking || state is AccessPreparingAd) return;
    state = const AccessChecking();

    final repo = ref.read(accessRepositoryProvider);
    final result = await repo.accessOptions(_fortuneId);
    state = result.fold(
      onSuccess: (options) {
        _lastOptions = options;
        switch (options.accessState) {
          case 'vip':
          case 'free':
            return const AccessProceed();
          case 'choice':
            return AccessSheet(options);
          default:
            return const AccessLimitReached();
        }
      },
      onFailure: AccessError.new,
    );
  }

  /// «دیدن تبلیغ و گرفتن فال» — run the mediation chain to one verified
  /// reward, automatic fallback on availability failures only.
  Future<void> watchAd() async {
    if (state is AccessPreparingAd) return;
    state = const AccessPreparingAd();

    final repo = ref.read(accessRepositoryProvider);
    final key = _idempotencyKey ??= const Uuid().v4();

    final created = await repo.createMediation(_fortuneId, key);
    var session = created.valueOrNull;
    if (session == null) {
      _rotateKey();
      state = AccessError(created.failureOrNull!);
      return;
    }

    while (true) {
      final current = session.current;
      if (current == null) break;
      final sid = session.sessionId;

      final outcome = await playRewardedAd(
        provider: current.provider,
        config: current.clientConfig,
        timeoutMs: current.loadTimeoutMs,
      );

      if (outcome == 'completed') {
        final unlock = await _awaitVerification(repo, sid, current);
        if (unlock != null) {
          state = AccessProceed(adEntitlementId: unlock);
          return;
        }
        // Server never confirmed: no unlock, and NO fallback to another
        // provider (could double-show ads for one reward).
        await repo.reportFailure(
          sid,
          current.attemptNumber,
          'verification_failed',
        );
        _rotateKey();
        state = const AccessAdsExhausted();
        return;
      }

      if (outcome == 'skipped') {
        // The user closed the ad — never auto-try another provider.
        await repo.reportFailure(sid, current.attemptNumber, 'skipped');
        _rotateKey();
        final options = _lastOptions;
        state = options != null ? AccessSheet(options) : const AccessIdle();
        return;
      }

      var reason = outcome;
      if (!_fallbackReasons.contains(outcome)) reason = 'ad_unavailable';
      final reported = await repo.reportFailure(
        sid,
        current.attemptNumber,
        reason,
      );
      final next = reported.valueOrNull;
      if (next == null) {
        _rotateKey();
        state = AccessError(reported.failureOrNull!);
        return;
      }
      session = next;
    }

    // Chain over without a reward.
    _rotateKey();
    if (session.status == 'rewarded') {
      final status = await repo.status(session.sessionId);
      final unlock = status.valueOrNull?.entitlementId;
      state = AccessProceed(adEntitlementId: unlock);
      return;
    }
    state = const AccessAdsExhausted();
  }

  /// Poll until the provider's server callback lands (or patience runs out).
  Future<String?> _awaitVerification(
    AccessRepository repo,
    String sessionId,
    ProviderHandle current,
  ) async {
    final timeout = Duration(milliseconds: current.verifyTimeoutMs);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await repo.status(sessionId);
      final status = result.valueOrNull;
      if (status != null) {
        if (status.entitlementId != null) return status.entitlementId;
        if (status.status != 'attempting' && status.status != 'created') {
          return null;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  /// Back to idle after a submit or when the user leaves the flow.
  void reset() {
    _rotateKey();
    state = const AccessIdle();
  }

  void _rotateKey() {
    _idempotencyKey = null;
  }
}

final accessRepositoryProvider = Provider<AccessRepository>((ref) {
  return AccessRepository(ref.watch(apiClientProvider));
});

final accessFlowControllerProvider = NotifierProvider.autoDispose.family<
    AccessFlowController,
    AccessFlowState,
    String>(AccessFlowController.new);
