/// What a reading costs THIS user right now, as the backend decides it
/// (Sprint 04 / doc 53). The client never computes entitlements.
class EntitlementStatus {
  const EntitlementStatus({
    required this.covered,
    required this.source,
    required this.cost,
  });

  /// True when readings are covered (active subscription) — no coins needed.
  final bool covered;

  /// 'subscription' when covered; null otherwise.
  final String? source;

  /// Coins per reading when not covered; 0 when covered.
  final int cost;

  bool get hasActiveSubscription => covered && source == 'subscription';
}
