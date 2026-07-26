import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/history/application/history_controller.dart';
import 'package:fortune_app/features/history/domain/history_repository.dart';
import 'package:fortune_app/features/profile/application/profile_controller.dart';
import 'package:fortune_app/features/profile/domain/user_profile.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reflections/application/reflection_controller.dart';
import 'package:fortune_app/features/reflections/data/reflection_repository.dart';
import 'package:fortune_app/features/reflections/domain/reflection.dart';

/// A profile that is simply not there — the honest state for a test that is
/// not about profiles. Nothing is personalized and nothing is fetched.
class InertProfile extends ProfileController {
  @override
  Future<UserProfile?> build() async => null;
}

/// A history that answers instantly and empty, so no test reaches a network.
class NoHistory implements HistoryRepository {
  @override
  Future<Result<ReadingListPage>> list({String? cursor}) async =>
      const Success(ReadingListPage(items: [], nextCursor: null));

  @override
  Future<Result<Reading>> byId(String id) async => const ResultFailure(
        AppFailure(kind: FailureKind.notFound, messageKey: 'notFound'),
      );
}

/// A journal with nothing in it, which is what a test that is not about the
/// journal should find.
class NoReflections implements ReflectionRepository {
  @override
  Future<Result<ReflectionPage>> list({String? cursor}) async =>
      const Success(ReflectionPage(items: [], nextCursor: null));

  @override
  Future<Result<Reflection?>> forReading(String readingId) async =>
      const Success(null);

  @override
  Future<Result<ReflectionLine>> line(Feeling feeling) async =>
      const ResultFailure(
        AppFailure(kind: FailureKind.notFound, messageKey: 'notFound'),
      );

  @override
  Future<Result<Reflection>> save({
    required String? readingId,
    required Feeling feeling,
    required String note,
  }) async =>
      const ResultFailure(
        AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout'),
      );

  @override
  Future<Result<String>> remove(String id) async => Success(id);
}

/// What the reading screen depends on beyond the reading itself: it may end
/// with «بعد از این» and a private note, which read the profile, the history
/// and the journal. Any test that lands on that screen declares these instead
/// of letting the real startup, auth and network run inside a widget test.
List<Override> readingScreenDeps({
  ProfileController Function() profile = InertProfile.new,
}) =>
    [
      profileControllerProvider.overrideWith(profile),
      historyRepositoryProvider.overrideWithValue(NoHistory()),
      reflectionRepositoryProvider.overrideWithValue(NoReflections()),
    ];
