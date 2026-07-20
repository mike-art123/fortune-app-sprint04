import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/wallet_repository_impl.dart';
import '../domain/entitlement_status.dart';
import '../domain/wallet_repository.dart';
import '../domain/wallet_summary.dart';

/// Explicit wallet lifecycle — no boolean soup.
sealed class WalletState {
  const WalletState();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletLoaded extends WalletState {
  const WalletLoaded(this.summary, {this.entitlement});

  final WalletSummary summary;

  /// Sprint 04: the backend's word on reading cost / subscription coverage.
  /// Null when the entitlement lookup failed — the wallet itself still shows;
  /// the page simply omits the pricing line rather than inventing one.
  final EntitlementStatus? entitlement;
}

final class WalletFailed extends WalletState {
  const WalletFailed(this.failure);
  final AppFailure failure;
}

/// Drives the wallet surface. Balance is displayed exactly as the backend
/// reports it — the client never invents or adjusts a number.
class WalletController extends AutoDisposeNotifier<WalletState> {
  @override
  WalletState build() {
    _load();
    return const WalletLoading();
  }

  Future<void> _load() async {
    final repository = ref.read(walletRepositoryProvider);
    final walletFuture = repository.fetch();
    final entitlementFuture = repository.entitlement();

    final walletResult = await walletFuture;
    final entitlementResult = await entitlementFuture;

    state = walletResult.fold(
      onSuccess: (summary) => WalletLoaded(summary, entitlement: entitlementResult.valueOrNull),
      onFailure: WalletFailed.new,
    );
  }

  Future<void> retry() async {
    state = const WalletLoading();
    await _load();
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(apiClientProvider));
});

final walletControllerProvider = NotifierProvider.autoDispose<WalletController, WalletState>(
  WalletController.new,
);
