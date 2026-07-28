import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/intention.dart';

class IntentionRepositoryImpl implements IntentionsRepository {
  const IntentionRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Intention>>> list() async {
    final result = await _api.get('/readings/intentions');
    return result.fold(
      onSuccess: (data) {
        try {
          final rawItems = data['items'];
          if (rawItems is! List) {
            throw const FormatException('intentions payload missing items');
          }
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(_fromJson)
              .toList(growable: false);
          return Success(items);
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }

  Intention _fromJson(Map<String, dynamic> json) {
    return Intention(
      id: json['id'] as String,
      fortuneId: json['fortune'] as String,
      text: json['intention'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
