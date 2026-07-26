import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/user_profile.dart';

/// Profile + onboarding surface (scope §16). The backend is the single source
/// of truth for onboarding state; this layer only moves JSON.
class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiClient _api;

  Future<Result<UserProfile>> fetch() async {
    final result = await _api.get('/profile');
    return result.fold(
      onSuccess: (data) => Success(UserProfile.fromJson(data)),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<UserProfile>> completeOnboarding({
    required String displayName,
    required String birthMonth,
  }) async {
    final result = await _api.post(
      '/profile/onboarding',
      body: {'displayName': displayName, 'birthMonth': birthMonth},
    );
    return result.fold(
      onSuccess: (data) => Success(UserProfile.fromJson(data)),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<UserProfile>> update({
    String? displayName,
    String? birthMonth,
  }) async {
    final result = await _api.patch(
      '/profile',
      body: {
        if (displayName != null) 'displayName': displayName,
        if (birthMonth != null) 'birthMonth': birthMonth,
      },
    );
    return result.fold(
      onSuccess: (data) => Success(UserProfile.fromJson(data)),
      onFailure: ResultFailure.new,
    );
  }
}
