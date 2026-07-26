import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/history_summary.dart';

/// Fetches the journal's summary for one window (scope §6).
class HistorySummaryRepository {
  const HistorySummaryRepository(this._api);

  final ApiClient _api;

  Future<Result<HistorySummary>> forRange(SummaryRange range) async {
    final result = await _api.get(
      '/history/summary',
      query: {'range': range.wire},
    );
    return result.fold(
      onSuccess: (data) {
        try {
          return Success(summaryFromJson(data, range));
        } catch (e) {
          return ResultFailure(ErrorMapper.parsing(e));
        }
      },
      onFailure: ResultFailure.new,
    );
  }
}

/// Pure translation of the server's reply, so it can be tested without a
/// network. Anything missing or of the wrong type is simply absent — a summary
/// is never worth an exception thrown at the reader.
HistorySummary summaryFromJson(Map<String, dynamic> json, SummaryRange asked) {
  final summary = json['summary'];
  if (summary is! String || summary.isEmpty) {
    throw const FormatException('summary payload missing summary');
  }

  final rawFacts = json['facts'];
  final facts = rawFacts is List
      ? rawFacts.whereType<String>().toList(growable: false)
      : const <String>[];

  final rawTallies = json['byFortune'];
  final byFortune = rawTallies is List
      ? rawTallies
          .whereType<Map<String, dynamic>>()
          .map(_tallyFrom)
          .whereType<FortuneTally>()
          .toList(growable: false)
      : const <FortuneTally>[];

  final rawSources = json['sourceIds'];
  final sourceIds = rawSources is List
      ? rawSources.whereType<String>().toList(growable: false)
      : const <String>[];

  final label = json['rangeLabelFa'];
  final total = json['total'];
  final previous = json['previousTotal'];

  return HistorySummary(
    range: asked,
    rangeLabel: label is String ? label : '',
    total: total is int ? total : 0,
    previousTotal: previous is int ? previous : 0,
    byFortune: byFortune,
    facts: facts,
    summary: summary,
    writtenByAi: json['source'] == 'ai',
    sourceIds: sourceIds,
  );
}

FortuneTally? _tallyFrom(Map<String, dynamic> json) {
  final id = json['fortuneId'];
  final title = json['titleFa'];
  final count = json['count'];
  if (id is! String || title is! String || count is! int) return null;
  return FortuneTally(fortuneId: id, title: title, count: count);
}
