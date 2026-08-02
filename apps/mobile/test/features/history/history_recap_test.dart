import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/features/history/domain/history_recap.dart';
import 'package:fortune_app/features/history/domain/history_summary.dart';

HistorySummary _summary({
  int total = 5,
  int previousTotal = 3,
  List<FortuneTally> byFortune = const [
    FortuneTally(fortuneId: 'hafez', title: 'فال حافظ', count: 2),
  ],
}) {
  return HistorySummary(
    range: SummaryRange.last30,
    rangeLabel: 'سی روز گذشته',
    total: total,
    previousTotal: previousTotal,
    byFortune: byFortune,
    facts: const [],
    summary: 'در سی روز گذشته ۵ فال گرفتی.',
    writtenByAi: false,
    sourceIds: const [],
  );
}

/// «نگاهی به گذشته» arrives from the server as one finished Persian sentence,
/// which is what an English reader used to be handed. The paragraph is only
/// arithmetic, so the app says it again in the language on screen.
void main() {
  test('Persian is left exactly as the server wrote it', () {
    // Not a detail: Persian is every web and Play reader today, and null is
    // what keeps their screen byte-for-byte unchanged.
    expect(recapFor(_summary(), const Locale('fa')), isNull);
  });

  test('English says the whole thing in English', () {
    final recap = recapFor(_summary(), const Locale('en'));

    expect(
      recap,
      'You took 5 fortunes in the last 30 days '
      '— 2 more than the period before. '
      'You reached for Hafez most — 2 times.',
    );
    // Nothing in Arabic script survived into it, fortune name included.
    final arabic = recap!.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
    expect(arabic, isFalse);
  });

  test('Arabic and Turkish name the fortune their own way', () {
    expect(recapFor(_summary(), const Locale('ar')), contains('فأل حافظ'));
    expect(recapFor(_summary(), const Locale('tr')), contains('Hafız Falı'));
    expect(recapFor(_summary(), const Locale('tr')), startsWith('Son 30'));
  });

  test('fewer than last time is said as fewer, not as more', () {
    final recap = recapFor(
      _summary(total: 2, previousTotal: 5),
      const Locale('en'),
    );

    expect(recap, contains('3 fewer than the period before'));
  });

  test('a first period is not compared with one that never happened', () {
    final recap = recapFor(
      _summary(total: 2, previousTotal: 0),
      const Locale('en'),
    );

    expect(recap, isNot(contains('period before')));
  });

  test('one reading of something is not called a habit', () {
    final recap = recapFor(
      _summary(
        byFortune: const [
          FortuneTally(fortuneId: 'hafez', title: 'فال حافظ', count: 1),
        ],
      ),
      const Locale('en'),
    );

    expect(recap, isNot(contains('most')));
  });

  test('an empty stretch says so rather than counting to zero', () {
    final recap = recapFor(
      _summary(total: 0, previousTotal: 0, byFortune: const []),
      const Locale('en'),
    );

    expect(recap, "You haven't taken a fortune in the last 30 days.");
  });
}
