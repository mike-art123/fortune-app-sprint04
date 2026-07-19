import '../domain/wallet_summary.dart';

/// Wire-format mapping for GET /wallet (data layer only).
abstract final class WalletDto {
  static WalletSummary fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    final rawTransactions = json['transactions'];

    if (balance is! int || rawTransactions is! List) {
      throw const FormatException('wallet payload missing required fields');
    }

    final entries = rawTransactions
        .whereType<Map<String, dynamic>>()
        .map(_entryFromJson)
        .toList(growable: false);

    return WalletSummary(balance: balance, entries: entries);
  }

  static CoinEntry _entryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final kind = json['kind'];
    final reason = json['reason'];
    final createdAt = json['createdAt'];

    if (id is! String || amount is! int || kind is! String) {
      throw const FormatException('coin entry missing required fields');
    }

    return CoinEntry(
      id: id,
      amount: amount,
      kind: kind,
      reason: reason is String ? reason : null,
      createdAt: createdAt is String
          ? (DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
