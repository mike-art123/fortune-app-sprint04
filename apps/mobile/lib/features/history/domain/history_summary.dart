import '../../../shared/models/localized_text.dart';

/// The windows the journal can look back over (scope §6). A closed list, and
/// the same three names the server knows.
enum SummaryRange { last7, last30, last90 }

extension SummaryRangeWire on SummaryRange {
  String get wire => switch (this) {
        SummaryRange.last7 => 'last7',
        SummaryRange.last30 => 'last30',
        SummaryRange.last90 => 'last90',
      };

  /// The chip label. Short, because it sits next to two others.
  LocalizedText get label => switch (this) {
        SummaryRange.last7 => const LocalizedText(
            fa: 'هفته',
            en: 'Week',
            ar: 'أسبوع',
            tr: 'Hafta',
          ),
        SummaryRange.last30 => const LocalizedText(
            fa: 'ماه',
            en: 'Month',
            ar: 'شهر',
            tr: 'Ay',
          ),
        SummaryRange.last90 => const LocalizedText(
            fa: 'سه ماه',
            en: '3 months',
            ar: '٣ أشهر',
            tr: '3 ay',
          ),
      };

  String get labelFa => label.fa;
}

/// How many times one fortune was opened in the window.
class FortuneTally {
  const FortuneTally({
    required this.fortuneId,
    required this.title,
    required this.count,
  });

  final String fortuneId;
  final String title;
  final int count;
}

/// What the journal says back about a stretch of time (scope §6).
///
/// [summary] is the sentence shown. [facts] is what the app counted, kept
/// separately so the reader can always see the plain arithmetic behind the
/// phrasing. [sourceIds] are the readings every number came from — the receipt.
class HistorySummary {
  const HistorySummary({
    required this.range,
    required this.rangeLabel,
    required this.total,
    required this.previousTotal,
    required this.byFortune,
    required this.facts,
    required this.summary,
    required this.writtenByAi,
    required this.sourceIds,
  });

  final SummaryRange range;
  final String rangeLabel;
  final int total;
  final int previousTotal;
  final List<FortuneTally> byFortune;
  final List<String> facts;
  final String summary;

  /// True when a model phrased it. Shown to the reader, never hidden — a
  /// sentence about their own life should say where it came from.
  final bool writtenByAi;
  final List<String> sourceIds;

  bool get isEmpty => total == 0;
}
