import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/entitlement_status.dart';
import '../domain/wallet_repository.dart';
import '../domain/wallet_summary.dart';
import 'entitlement_dto.dart';
import 'wallet_dto.dart';

/// Sprint 04: identity travels as the bearer token (auth interceptor) — the
/// temporary x-anon-id header is gone.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Result<WalletSummary>> fetch() async {
    final result = await _api.get('/wallet');
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(WalletDto.fromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }

  @override
  Future<Result<EntitlementStatus>> entitlement() async {
    final result = await _api.get('/entitlements/me');
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(EntitlementDto.fromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }
}
