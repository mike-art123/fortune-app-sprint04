import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../../history/domain/history_repository.dart';
import '../../reading/data/reading_dto.dart';
import '../domain/saved_repository.dart';

class SavedRepositoryImpl implements SavedRepository {
  const SavedRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Result<ReadingListPage>> list({String? cursor}) async {
    final result = await _api.get(
      '/readings/saved',
      query: cursor == null ? null : {'cursor': cursor},
    );
    return result.fold(
      onSuccess: (data) {
        try {
          final rawItems = data['items'];
          if (rawItems is! List) {
            throw const FormatException('saved payload missing items');
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
  Future<Result<bool>> save(String id) => _setSaved(id: id, save: true);

  @override
  Future<Result<bool>> unsave(String id) => _setSaved(id: id, save: false);

  Future<Result<bool>> _setSaved({
    required String id,
    required bool save,
  }) async {
    final path = '/readings/$id/save';
    final result = await (save ? _api.post(path) : _api.delete(path));
    return result.fold(
      onSuccess: (data) => Success(data['saved'] == true),
      onFailure: ResultFailure.new,
    );
  }
}
