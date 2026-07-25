import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/platform/telegram_invoice.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/vip_repository.dart';
import '../domain/vip_status.dart';

/// Explicit VIP lifecycle — no boolean soup.
sealed class VipState {
  const VipState();
}

final class VipLoading extends VipState {
  const VipLoading();
}

final class VipLoaded extends VipState {
  const VipLoaded(this.status, {this.purchasing = false});

  final VipStatus status;

  /// True while an invoice is open / activation is being confirmed.
  final bool purchasing;
}

final class VipFailed extends VipState {
  const VipFailed(this.failure);
  final AppFailure failure;
}

/// Drives the VIP page. Status is displayed exactly as the backend reports it;
/// a purchase opens Telegram's own Stars sheet and then re-reads the backend —
/// the client never asserts VIP on its own.
class VipController extends AutoDisposeNotifier<VipState> {
  @override
  VipState build() {
    _load();
    return const VipLoading();
  }

  Future<void> _load() async {
    final repository = ref.read(vipRepositoryProvider);
    final result = await repository.status();
    state = result.fold(
      onSuccess: (status) => VipLoaded(status),
      onFailure: VipFailed.new,
    );
  }

  Future<void> retry() async {
    state = const VipLoading();
    await _load();
  }

  /// Returns the sheet outcome: paid | cancelled | failed | pending |
  /// unavailable | error. On `paid`, polls the backend until the webhook has
  /// activated the subscription (or a short patience window runs out).
  Future<String> purchase(String planId) async {
    final current = state;
    if (current is! VipLoaded || current.purchasing) return 'busy';
    state = VipLoaded(current.status, purchasing: true);

    final repository = ref.read(vipRepositoryProvider);
    final linkResult = await repository.invoiceLink(planId);
    final link = linkResult.valueOrNull;
    if (link == null) {
      state = VipLoaded(current.status);
      return 'error';
    }

    final outcome = await openTelegramInvoice(link);
    if (outcome == 'paid') {
      await _confirmActivation(repository);
    } else {
      state = VipLoaded(current.status);
    }
    return outcome;
  }

  /// The webhook activates asynchronously; poll briefly instead of guessing.
  Future<void> _confirmActivation(VipRepository repository) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final result = await repository.status();
      final status = result.valueOrNull;
      if (status != null && status.isVip) {
        state = VipLoaded(status);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    await _load();
  }
}

final vipRepositoryProvider = Provider<VipRepository>((ref) {
  return VipRepository(ref.watch(apiClientProvider));
});

final vipControllerProvider =
    NotifierProvider.autoDispose<VipController, VipState>(VipController.new);
