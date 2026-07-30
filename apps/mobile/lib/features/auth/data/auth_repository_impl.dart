import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';
import 'auth_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Result<AuthLogin>> loginWithTelegram(String initData) =>
      _login('/auth/telegram', {'initData': initData});

  @override
  Future<Result<AuthLogin>> loginAsGuest(String deviceId) =>
      _login('/auth/guest', {'deviceId': deviceId});

  Future<Result<AuthLogin>> _login(
    String path,
    Map<String, String> body,
  ) async {
    final result = await _api.post(path, body: body);
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(AuthDto.fromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }
}
