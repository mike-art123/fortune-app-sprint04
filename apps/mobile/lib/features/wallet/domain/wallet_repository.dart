import '../../../core/result/result.dart';
import 'entitlement_status.dart';
import 'wallet_summary.dart';

/// Contract the application layer depends on — never the implementation.
abstract interface class WalletRepository {
  Future<Result<WalletSummary>> fetch();

  /// Sprint 04: the backend's word on what a reading costs this user.
  Future<Result<EntitlementStatus>> entitlement();
}
