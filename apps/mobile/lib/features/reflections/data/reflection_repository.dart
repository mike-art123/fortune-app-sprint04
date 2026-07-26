import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/reflection.dart';

/// The journal's only door to the server (scope §8). Nothing here reads a note
/// for any purpose other than carrying it home.
class ReflectionRepository {
  const ReflectionRepository(this._api);

  final ApiClient _api;

  Future<Result<ReflectionPage>> list({String? cursor}) async {
    final result = await _api.get(
      '/reflections',
      query: cursor == null ? null : {'cursor': cursor},
    );
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(pageFromJson(data));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }

  /// The entry attached to one reading, or null when none was written.
  Future<Result<Reflection?>> forReading(String readingId) async {
    final result = await _api.get('/reflections/reading/$readingId');
    return result.fold(
      onSuccess: (data) => Success(Reflection.fromJson(data)),
      onFailure: ResultFailure.new,
    );
  }

  Future<Result<Reflection>> save({
    required String? readingId,
    required Feeling feeling,
    required String note,
  }) async {
    final result = await _api.put(
      '/reflections',
      body: {
        if (readingId != null) 'readingId': readingId,
        'feeling': feeling.wire,
        'note': note,
      },
    );
    return result.fold(
      onSuccess: (data) {
        final saved = Reflection.fromJson(data);
        if (saved == null) {
          return ResultFailure(
            ErrorMapper.parsing(const FormatException('reflection payload')),
          );
        }
        return Success(saved);
      },
      onFailure: ResultFailure.new,
    );
  }

  /// The line to show under the note. Only the chosen word is sent.
  Future<Result<ReflectionLine>> line(Feeling feeling) async {
    final result = await _api.get(
      '/reflections/prompt',
      query: {'feeling': feeling.wire},
    );
    return result.fold(
      onSuccess: (data) {
        final line = ReflectionLine.fromJson(data);
        if (line == null) {
          return ResultFailure(
            ErrorMapper.parsing(const FormatException('prompt payload')),
          );
        }
        return Success(line);
      },
      onFailure: ResultFailure.new,
    );
  }

  /// Answers with the id that was removed, so nothing has to be guessed.
  Future<Result<String>> remove(String id) async {
    final result = await _api.delete('/reflections/$id');
    return result.fold(
      onSuccess: (data) => Success(data['id'] as String? ?? id),
      onFailure: ResultFailure.new,
    );
  }
}

/// Pure translation, so it can be tested without a network. A malformed entry
/// is dropped rather than allowed to take the whole page down with it.
ReflectionPage pageFromJson(Map<String, dynamic> json) {
  final raw = json['items'];
  if (raw is! List) {
    throw const FormatException('reflection page missing items');
  }
  final items = raw
      .whereType<Map<String, dynamic>>()
      .map(Reflection.fromJson)
      .whereType<Reflection>()
      .toList(growable: false);
  final next = json['nextCursor'];
  return ReflectionPage(items: items, nextCursor: next is String ? next : null);
}
