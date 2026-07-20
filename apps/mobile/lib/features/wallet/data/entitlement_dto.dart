import '../domain/entitlement_status.dart';

/// Wire-format mapping for GET /entitlements/me (data layer only).
abstract final class EntitlementDto {
  static EntitlementStatus fromJson(Map<String, dynamic> json) {
    final covered = json['covered'];
    final cost = json['cost'];
    final source = json['source'];

    if (covered is! bool || cost is! int) {
      throw const FormatException(
        'entitlement payload missing required fields',
      );
    }

    return EntitlementStatus(
      covered: covered,
      source: source is String ? source : null,
      cost: cost,
    );
  }
}
