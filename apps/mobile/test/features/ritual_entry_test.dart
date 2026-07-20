import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/ritual_entry/presentation/pages/ritual_entry_page.dart';
import 'package:fortune_app/features/ritual_entry/presentation/widgets/whisper_field.dart';

Widget host(String fortuneId) => ProviderScope(
  child: MaterialApp(
    locale: SupportedLocales.fa,
    supportedLocales: SupportedLocales.all,
    localizationsDelegates: SupportedLocales.delegates,
    theme: AppTheme.dark(),
    home: RitualEntryPage(fortuneId: fortuneId),
  ),
);

void main() {
  testWidgets('hafez entry shows ritual line, whisper, and CTA', (
    tester,
  ) async {
    await tester.pumpWidget(host('hafez'));
    await tester.pumpAndSettle();

    expect(find.text('نیتت را در دل نگه دار.'), findsOneWidget);
    expect(find.byType(WhisperField), findsOneWidget);
    expect(find.text('فال حافظ را باز کن'), findsOneWidget);
  });

  testWidgets('love entry renders two whispers joined by و', (tester) async {
    await tester.pumpWidget(host('love'));
    await tester.pumpAndSettle();

    expect(find.byType(WhisperField), findsNWidgets(2));
    expect(find.text('و'), findsOneWidget);
  });

  testWidgets('love: sealing with one name shows gentle guidance', (
    tester,
  ) async {
    await tester.pumpWidget(host('love'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(WhisperField).first, 'سارا');
    await tester.tap(find.text('سازگاری را ببین'));
    await tester.pumpAndSettle();

    expect(
      find.text('برای دیدنِ سازگاری، هر دو نام را بنویس.'),
      findsOneWidget,
    );
  });

  testWidgets('unknown fortune id shows branded recovery', (tester) async {
    await tester.pumpWidget(host('nonsense'));
    await tester.pumpAndSettle();

    expect(find.text('این صفحه پیدا نشد'), findsOneWidget);
  });

  testWidgets('entry renders right-to-left under Persian locale', (
    tester,
  ) async {
    await tester.pumpWidget(host('hafez'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(RitualEntryPage));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
