import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../../reading/data/reading_dto.dart';
import '../../reading/domain/reading.dart';
import '../domain/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Result<ReadingListPage>> list({String? cursor}) async {
    final result = await _api.get(
      '/readings',
      query: cursor == null ? null : {'cursor': cursor},
    );
    return result.fold(
      onSuccess: (data) {
        try {
          final rawItems = data['items'];
          if (rawItems is! List) {
            throw const FormatException('history payload missing items');
          }
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(ReadingDto.fromJson)
              .toList(growable: false);
          final next = data['nextCursor'];
          return Success(
            ReadingListPage(
              items: items,
              nextCursor: next is String ? next : null,
            ),
          );
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }

  @override
  Future<Result<Reading>> byId(String id) async {
    final result = await _api.get('/readings/$id');
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(ReadingDto.fromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }
}
