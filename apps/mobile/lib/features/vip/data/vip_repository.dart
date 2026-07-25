import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/vip_status.dart';

/// VIP surface: read status/plans, ask for a Stars invoice link. Activation
/// itself only ever happens server-side via the verified Telegram webhook.
class VipRepository {
  const VipRepository(this._api);

  final ApiClient _api;

  Future<Result<VipStatus>> status() async {
    final result = await _api.get('/vip/status');
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(_statusFromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<String>> invoiceLink(String planId) async {
    final result = await _api.post('/vip/invoice', body: {'planId': planId});
    return result.fold(
      onSuccess: (data) {
        final link = data['link'];
        if (link is String && link.isNotEmpty) return Success(link);
        return ResultFailure(ErrorMapper.parsing('missing invoice link'));
      },
      onFailure: ResultFailure.new,
    );
  }

  VipStatus _statusFromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'];
    final plans = <VipPlan>[
      if (rawPlans is List)
        for (final p in rawPlans.whereType<Map<String, dynamic>>())
          VipPlan(
            id: p['id'] as String,
            titleFa: p['titleFa'] as String,
            stars: (p['stars'] as num).toInt(),
            days: (p['days'] as num).toInt(),
          ),
    ];
    final expiresRaw = json['expiresAt'];
    return VipStatus(
      isVip: json['isVip'] == true,
      plan: json['plan'] as String?,
      expiresAt: expiresRaw is String ? DateTime.tryParse(expiresRaw) : null,
      plans: plans,
    );
  }
}
