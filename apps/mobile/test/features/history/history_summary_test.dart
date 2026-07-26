import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/history/application/history_summary_controller.dart';
import 'package:fortune_app/features/history/domain/history_summary.dart';
import 'package:fortune_app/features/history/presentation/widgets/history_summary_card.dart';

HistorySummary _summary({
  bool writtenByAi = false,
  String text = 'در سی روز گذشته ۲ فال گرفتی.',
}) {
  return HistorySummary(
    range: SummaryRange.last30,
    rangeLabel: 'سی روز گذشته',
    total: 2,
    previousTotal: 0,
    byFortune: const [
      FortuneTally(fortuneId: 'hafez', title: 'فال حافظ', count: 2),
    ],
    facts: const ['در سی روز گذشته ۲ فال گرفتی.'],
    summary: text,
    writtenByAi: writtenByAi,
    sourceIds: const ['r1', 'r2'],
  );
}

Widget host(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: SingleChildScrollView(child: HistorySummaryCard()),
      ),
    ),
  );
}

/// The journal may say what a stretch of time looked like, but it must never
/// stand between someone and their own readings, and it must say plainly when
/// a machine wrote the sentence.
void main() {
  testWidgets('shows the sentence and the counts behind it', (tester) async {
    await tester.pumpWidget(
      host([historySummaryProvider.overrideWith((ref) async => _summary())]),
    );
    await tester.pumpAndSettle();

    expect(find.text('نگاهی به گذشته'), findsOneWidget);
    expect(find.text('در سی روز گذشته ۲ فال گرفتی.'), findsOneWidget);
    expect(find.text('فال حافظ · ۲'), findsOneWidget);
  });

  testWidgets('says so when the sentence was written by the assistant', (
    tester,
  ) async {
    await tester.pumpWidget(
      host([
        historySummaryProvider.overrideWith(
          (ref) async => _summary(writtenByAi: true, text: 'ماه آرامی داشتی.'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('ماه آرامی داشتی.'), findsOneWidget);
    expect(
      find.text('این جمله را دستیار از شمارشِ خودِ فال‌هایت نوشته است.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed summary is silence, never an error', (tester) async {
    await tester.pumpWidget(
      host([historySummaryProvider.overrideWith((ref) async => null)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('نگاهی به گذشته'), findsOneWidget);
    expect(find.textContaining('خطا'), findsNothing);
  });

  testWidgets('choosing a window changes what is asked for', (tester) async {
    final asked = <SummaryRange>[];
    await tester.pumpWidget(
      host([
        historySummaryProvider.overrideWith((ref) async {
          asked.add(ref.watch(summaryRangeProvider));
          return _summary();
        }),
      ]),
    );
    await tester.pumpAndSettle();
    expect(asked, [SummaryRange.last30]);

    await tester.tap(find.text('سه ماه'));
    await tester.pumpAndSettle();
    expect(asked, [SummaryRange.last30, SummaryRange.last90]);
  });
}
