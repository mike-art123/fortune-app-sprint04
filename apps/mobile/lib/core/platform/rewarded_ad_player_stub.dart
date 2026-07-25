/// Non-web resolution: rewarded ads need the web SDKs, so outside a web build
/// every attempt reports `ad_unavailable` — the mediation chain then falls
/// through or ends gracefully. Never a crash.
Future<String> playRewardedAd({
  required String provider,
  required Map<String, String> config,
  required int timeoutMs,
}) async {
  return 'ad_unavailable';
}
