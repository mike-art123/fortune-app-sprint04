/// One VIP plan as the backend prices it (Telegram Stars — never coins).
class VipPlan {
  const VipPlan({
    required this.id,
    required this.titleFa,
    required this.stars,
    required this.days,
  });

  final String id;
  final String titleFa;
  final int stars;
  final int days;
}

/// Backend-authoritative VIP state plus the purchasable plans.
class VipStatus {
  const VipStatus({
    required this.isVip,
    required this.plan,
    required this.expiresAt,
    required this.plans,
  });

  final bool isVip;
  final String? plan;
  final DateTime? expiresAt;
  final List<VipPlan> plans;
}
