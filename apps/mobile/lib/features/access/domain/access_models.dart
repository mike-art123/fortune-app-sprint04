/// Backend-computed access decision for one fortune (coins do not exist).
class AccessOptions {
  const AccessOptions({
    required this.fortuneId,
    required this.isFreeNow,
    required this.freeUsesRemainingToday,
    required this.rewardedAdAvailable,
    required this.rewardedAdsRemainingToday,
    required this.accessState,
  });

  final String fortuneId;
  final bool isFreeNow;
  final int freeUsesRemainingToday;
  final bool rewardedAdAvailable;
  final int rewardedAdsRemainingToday;

  /// free | ad_required | unavailable — the server's word, never recomputed.
  final String accessState;
}

/// The provider the backend wants the client to attempt right now.
class ProviderHandle {
  const ProviderHandle({
    required this.attemptNumber,
    required this.provider,
    required this.clientConfig,
    required this.loadTimeoutMs,
    required this.verifyTimeoutMs,
  });

  final int attemptNumber;
  final String provider;
  final Map<String, String> clientConfig;
  final int loadTimeoutMs;
  final int verifyTimeoutMs;
}

/// One mediation session (attempt chain) for a pending fortune request.
class MediationSession {
  const MediationSession({
    required this.sessionId,
    required this.status,
    required this.current,
  });

  final String sessionId;

  /// created | attempting | rewarded | exhausted | cancelled | failed
  final String status;

  /// Null when the chain is over (rewarded/exhausted/cancelled/failed).
  final ProviderHandle? current;
}

/// Poll view while waiting for the server-verified reward.
class MediationStatus {
  const MediationStatus({
    required this.status,
    required this.entitlementId,
  });

  final String status;
  final String? entitlementId;
}
