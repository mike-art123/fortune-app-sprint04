import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_startup_state.dart';
import '../../../core/errors/app_failure.dart';
import '../../../features/splash/presentation/controllers/startup_controller.dart';
import '../../../shared/providers/shared_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Loads and holds the profile (scope §16). The router's onboarding gate reads
/// this: null → still unknown (hold on splash); completed=false → onboarding;
/// true → app. The fetch waits for startup (auth) to be ready, and the backend
/// is the source of truth, so no device or cache can re-trigger onboarding.
class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    // Rebuilds when startup transitions; never calls the API pre-auth.
    final startup = ref.watch(startupControllerProvider).valueOrNull;
    if (startup is! StartupReady) return null;

    final repo = ref.watch(profileRepositoryProvider);
    final result = await repo.fetch();
    return result.fold(
      onSuccess: (profile) => profile,
      onFailure: (failure) => throw failure,
    );
  }

  Future<AppFailure?> completeOnboarding({
    required String displayName,
    required String birthMonth,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.completeOnboarding(
      displayName: displayName,
      birthMonth: birthMonth,
    );
    return result.fold(
      onSuccess: (profile) {
        state = AsyncData(profile);
        return null;
      },
      onFailure: (failure) => failure,
    );
  }

  Future<AppFailure?> updateProfile({
    String? displayName,
    String? birthMonth,
    bool? personalizationOptOut,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.update(
      displayName: displayName,
      birthMonth: birthMonth,
      personalizationOptOut: personalizationOptOut,
    );
    return result.fold(
      onSuccess: (profile) {
        state = AsyncData(profile);
        return null;
      },
      onFailure: (failure) => failure,
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
  ProfileController.new,
);
