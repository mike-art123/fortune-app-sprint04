import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/history/data/history_summary_repository.dart';
import 'package:fortune_app/features/history/domain/history_summary.dart';

/// What the server sends is data, not a promise. Anything missing, mistyped or
/// unexpected must degrade to something the journal can still show.
void main() {
  test('reads a complete payload', () {
    final summary = summaryFromJson(const {
      'range': 'last30',
      'rangeLabelFa': 'سی روز گذشته',
      'total': 3,
      'previousTotal': 1,
      'byFortune': [
        {'fortuneId': 'hafez', 'titleFa': 'فال حافظ', 'count': 2},
        {'fortuneId': 'tarot', 'titleFa': 'تاروت', 'count': 1},
      ],
      'facts': ['در سی روز گذشته ۳ فال گرفتی؛ ۲ تا بیشتر از دورهٔ پیش.'],
      'summary': 'ماه پرکاری داشتی.',
      'source': 'ai',
      'sourceIds': ['r1', 'r2', 'r3'],
    }, SummaryRange.last30);

    expect(summary.total, 3);
    expect(summary.previousTotal, 1);
    expect(summary.writtenByAi, isTrue);
    expect(summary.byFortune.map((t) => t.title), ['فال حافظ', 'تاروت']);
    expect(summary.sourceIds, ['r1', 'r2', 'r3']);
  });

  test('drops malformed tallies instead of failing the whole summary', () {
    final summary = summaryFromJson(const {
      'summary': 'ماه آرامی داشتی.',
      'byFortune': [
        {'fortuneId': 'hafez', 'titleFa': 'فال حافظ', 'count': 2},
        {'fortuneId': 'tarot', 'count': 'زیاد'},
        'nonsense',
      ],
    }, SummaryRange.last7);

    expect(summary.byFortune.length, 1);
    expect(summary.byFortune.single.fortuneId, 'hafez');
    expect(summary.range, SummaryRange.last7);
  });

  test('treats missing numbers as zero rather than guessing', () {
    final summary = summaryFromJson(const {
      'summary': 'ماه آرامی داشتی.',
    }, SummaryRange.last90);

    expect(summary.total, 0);
    expect(summary.previousTotal, 0);
    expect(summary.facts, isEmpty);
    expect(summary.sourceIds, isEmpty);
    expect(summary.writtenByAi, isFalse);
    expect(summary.isEmpty, isTrue);
  });

  test('refuses a payload with no sentence at all', () {
    expect(
      () => summaryFromJson(const {'total': 3}, SummaryRange.last30),
      throwsA(isA<FormatException>()),
    );
  });

  test('every window has a wire name and a short label', () {
    expect(SummaryRange.values.map((r) => r.wire), [
      'last7',
      'last30',
      'last90',
    ]);
    expect(SummaryRange.values.map((r) => r.labelFa), [
      'هفته',
      'ماه',
      'سه ماه',
    ]);
  });
}
