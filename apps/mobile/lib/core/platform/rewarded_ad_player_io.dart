import '../ads/admob_service.dart';
import '../ads/rewarded_ad_service.dart';

/// Native resolution (the Play build): AdMob carries the `admob` provider,
/// and every other provider is web-only, so the mediation chain falls
/// through cleanly with `ad_unavailable` — the same contract as the web
/// adapters, reason for reason.
Future<String> playRewardedAd({
  required String provider,
  required Map<String, String> config,
  required int timeoutMs,
}) async {
  if (provider != 'admob') return 'ad_unavailable';
  final configured = config['adUnitId'] ?? '';
  final adUnitId = configured.isEmpty ? kAdmobRewardedAdUnitId : configured;
  return RewardedAdService.instance.play(
    adUnitId: adUnitId,
    timeoutMs: timeoutMs,
  );
}
