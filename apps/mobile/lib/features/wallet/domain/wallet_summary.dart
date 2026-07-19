/// One ledger entry as shown to the user. Amount is signed:
/// positive = credit, negative = debit.
class CoinEntry {
  const CoinEntry({
    required this.id,
    required this.amount,
    required this.kind,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final String kind;
  final String? reason;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;
}

/// The wallet as the backend reports it. The client never computes balances.
class WalletSummary {
  const WalletSummary({required this.balance, required this.entries});

  final int balance;
  final List<CoinEntry> entries;
}
