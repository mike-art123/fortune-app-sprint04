import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/access_models.dart';

/// Access + rewarded-ad mediation surface. Every decision comes from the
/// backend; this layer only moves JSON. No coin field exists in any contract.
class AccessRepository {
  const AccessRepository(this._api);

  final ApiClient _api;

  Future<Result<AccessOptions>> accessOptions(String fortuneId) async {
    final result = await _api.get('/access-options/$fortuneId');
    return result.fold(
      onSuccess: (data) => _parse(data, _optionsFromJson),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<MediationSession>> createMediation(
    String fortuneId,
    String idempotencyKey,
  ) async {
    final result = await _api.post(
      '/ads/mediation',
      body: {'fortuneId': fortuneId, 'idempotencyKey': idempotencyKey},
    );
    return result.fold(
      onSuccess: (data) => _parse(data, _sessionFromJson),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<MediationSession>> reportFailure(
    String sessionId,
    int attemptNumber,
    String reason,
  ) async {
    final result = await _api.post(
      '/ads/mediation/$sessionId/failure',
      body: {'attemptNumber': attemptNumber, 'reason': reason},
    );
    return result.fold(
      onSuccess: (data) => _parse(data, _sessionFromJson),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<MediationStatus>> status(String sessionId) async {
    final result = await _api.get('/ads/mediation/$sessionId');
    return result.fold(
      onSuccess: (data) => _parse(data, _statusFromJson),
      onFailure: ResultFailure.new,
    );
  }

  Future<void> cancel(String sessionId) async {
    await _api.post('/ads/mediation/$sessionId/cancel');
  }

  Future<Result<MediationStatus>> complete(String sessionId) async {
    final result = await _api.post('/ads/mediation/$sessionId/complete');
    return result.fold(
      onSuccess: (data) => _parse(data, _statusFromJson),
      onFailure: ResultFailure.new,
    );
  }

  Result<T> _parse<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return Success(fromJson(data));
    } catch (e) {
      return ResultFailure(ErrorMapper.parsing(e));
    }
  }

  AccessOptions _optionsFromJson(Map<String, dynamic> json) {
    return AccessOptions(
      fortuneId: json['fortuneId'] as String,
      isFreeNow: json['isFreeNow'] == true,
      freeUsesRemainingToday:
          (json['freeUsesRemainingToday'] as num?)?.toInt() ?? 0,
      rewardedAdAvailable: json['rewardedAdAvailable'] == true,
      rewardedAdsRemainingToday:
          (json['rewardedAdsRemainingToday'] as num?)?.toInt() ?? 0,
      accessState: json['accessState'] as String,
    );
  }

  MediationSession _sessionFromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current'];
    ProviderHandle? current;
    if (rawCurrent is Map<String, dynamic>) {
      final rawConfig = rawCurrent['clientConfig'];
      current = ProviderHandle(
        attemptNumber: (rawCurrent['attemptNumber'] as num).toInt(),
        provider: rawCurrent['provider'] as String,
        clientConfig: {
          if (rawConfig is Map<String, dynamic>)
            for (final entry in rawConfig.entries)
              entry.key: entry.value.toString(),
        },
        loadTimeoutMs: (rawCurrent['loadTimeoutMs'] as num?)?.toInt() ?? 12000,
        verifyTimeoutMs:
            (rawCurrent['verifyTimeoutMs'] as num?)?.toInt() ?? 20000,
      );
    }
    return MediationSession(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String,
      current: current,
    );
  }

  MediationStatus _statusFromJson(Map<String, dynamic> json) {
    return MediationStatus(
      status: json['status'] as String,
      entitlementId: json['entitlementId'] as String?,
    );
  }
}
