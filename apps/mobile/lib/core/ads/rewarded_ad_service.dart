import 'dart:async';
import 'dart:math' as math;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_service.dart';

/// One rewarded playback at a time, plus a warm cache for the next request.
///
/// Outcomes speak the mediation chain's canonical vocabulary (`completed`,
/// `skipped`, `no_fill`, `load_timeout`, `temporary_provider_error`) so the
/// access flow treats AdMob exactly like every other provider — and the
/// reward itself is still granted by the backend, never by this class.
final class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _warm;
  String? _warmUnitId;
  bool _warming = false;
  int _consecutiveLoadFailures = 0;
  Timer? _retry;

  /// Plays one rewarded ad and reports the canonical outcome. [timeoutMs]
  /// budgets the LOAD phase only — the watch phase belongs to the user (the
  /// web adapters learned that the hard way). Never throws; `completed` is
  /// reported only after the SDK's user-earned-reward callback fired.
  Future<String> play({
    required String adUnitId,
    required int timeoutMs,
  }) async {
    try {
      await AdmobService.ensureInitialized();

      var ad = _takeWarm(adUnitId);
      if (ad == null) {
        final loaded = await _load(adUnitId, Duration(milliseconds: timeoutMs));
        final failure = loaded.outcome;
        if (failure != null) return failure;
        ad = loaded.ad;
      }
      if (ad == null) return 'temporary_provider_error';
      return await _show(ad, adUnitId);
    } catch (error) {
      // An ad may fail; the ritual may not. Any unexpected SDK exception
      // becomes a canonical failure the mediation chain knows how to hold.
      logAdmob('unexpected error: $error');
      return 'temporary_provider_error';
    }
  }

  RewardedAd? _takeWarm(String adUnitId) {
    final ad = _warm;
    if (ad == null) return null;
    _warm = null;
    if (_warmUnitId != adUnitId) {
      // The backend switched ad units; the cached ad no longer matches.
      unawaited(ad.dispose());
      _warmUnitId = null;
      return null;
    }
    _warmUnitId = null;
    logAdmob('using preloaded ad');
    return ad;
  }

  Future<({RewardedAd? ad, String? outcome})> _load(
    String adUnitId,
    Duration timeout,
  ) async {
    final completer = Completer<({RewardedAd? ad, String? outcome})>();
    var timedOut = false;

    logAdmob('loading rewarded ad');
    unawaited(
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _consecutiveLoadFailures = 0;
            if (timedOut) {
              // Too late for this request — keep it warm for the next one.
              logAdmob('ad loaded after timeout; cached for the next ask');
              _storeWarm(ad, adUnitId);
              return;
            }
            logAdmob('ad loaded');
            completer.complete((ad: ad, outcome: null));
          },
          onAdFailedToLoad: (error) {
            _consecutiveLoadFailures += 1;
            logAdmob('ad failed to load: code ${error.code} ${error.message}');
            if (timedOut) return;
            final outcome =
                error.code == 3 ? 'no_fill' : 'temporary_provider_error';
            completer.complete((ad: null, outcome: outcome));
          },
        ),
      ),
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        timedOut = true;
        _consecutiveLoadFailures += 1;
        logAdmob('ad load timed out');
        return (ad: null, outcome: 'load_timeout');
      },
    );
  }

  Future<String> _show(RewardedAd ad, String adUnitId) {
    final completer = Completer<String>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => logAdmob('ad shown'),
      onAdFailedToShowFullScreenContent: (ad, error) {
        logAdmob('ad failed to show: ${error.message}');
        unawaited(ad.dispose());
        if (!completer.isCompleted) {
          completer.complete('temporary_provider_error');
        }
        _warmUp(adUnitId);
      },
      onAdDismissedFullScreenContent: (ad) {
        logAdmob(earned ? 'ad dismissed after reward' : 'ad dismissed early');
        unawaited(ad.dispose());
        if (!completer.isCompleted) {
          completer.complete(earned ? 'completed' : 'skipped');
        }
        _warmUp(adUnitId);
      },
    );

    unawaited(
      ad.show(
        onUserEarnedReward: (view, reward) {
          earned = true;
          logAdmob('user earned reward (${reward.amount} ${reward.type})');
        },
      ),
    );
    return completer.future;
  }

  void _storeWarm(RewardedAd ad, String adUnitId) {
    unawaited(_warm?.dispose() ?? Future<void>.value());
    _warm = ad;
    _warmUnitId = adUnitId;
  }

  /// Preloads the next ad so the following request opens instantly, retrying
  /// on an exponential backoff (1s, 2s, 4s … capped at 60s) and resting
  /// after five straight failures until the next playback attempt.
  void _warmUp(String adUnitId) {
    if (_warming || _warm != null) return;
    if (_consecutiveLoadFailures >= 5) {
      logAdmob('preload paused after repeated failures');
      return;
    }
    final delay = _consecutiveLoadFailures == 0
        ? Duration.zero
        : Duration(seconds: math.min(60, 1 << _consecutiveLoadFailures));
    _warming = true;
    _retry?.cancel();
    _retry = Timer(delay, () async {
      logAdmob('preloading next ad');
      final loaded = await _load(adUnitId, const Duration(seconds: 30));
      _warming = false;
      final ad = loaded.ad;
      if (ad != null) {
        _storeWarm(ad, adUnitId);
        logAdmob('next ad preloaded');
      } else {
        _warmUp(adUnitId);
      }
    });
  }

  /// Releases the warm ad and any pending retry timer.
  void dispose() {
    _retry?.cancel();
    _retry = null;
    _warming = false;
    final warm = _warm;
    _warm = null;
    _warmUnitId = null;
    if (warm != null) unawaited(warm.dispose());
  }
}
