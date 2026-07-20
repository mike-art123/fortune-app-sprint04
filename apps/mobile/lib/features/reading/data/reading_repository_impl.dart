import '../../../core/constants/header_keys.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../../fortunes/domain/fal_input.dart';
import '../domain/reading.dart';
import '../domain/reading_repository.dart';
import 'fal_input_payload.dart';
import 'reading_dto.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  const ReadingRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Result<Reading>> create(
    FalInput input, {
    String? idempotencyKey,
  }) async {
    final result = await _api.post(
      '/readings',
      body: FalInputPayload.toJson(input),
      headers: idempotencyKey == null ? null : {HeaderKeys.idempotencyKey: idempotencyKey},
    );
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
