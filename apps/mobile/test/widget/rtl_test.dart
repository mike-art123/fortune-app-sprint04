import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/app_strings.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/design_system/components/fortune_text_field.dart';

void main() {
  testWidgets('Persian locale renders right-to-left', (tester) async {
    late TextDirection direction;

    await tester.pumpWidget(
      MaterialApp(
        locale: SupportedLocales.fa,
        supportedLocales: SupportedLocales.all,
        localizationsDelegates: SupportedLocales.delegates,
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const Scaffold(body: FortuneTextField(hint: 'نیت'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(direction, TextDirection.rtl);
    expect(find.text('نیت'), findsOneWidget);
  });

  testWidgets('strings resolve per locale', (tester) async {
    late AppStrings fa;
    await tester.pumpWidget(
      MaterialApp(
        locale: SupportedLocales.fa,
        supportedLocales: SupportedLocales.all,
        localizationsDelegates: SupportedLocales.delegates,
        home: Builder(
          builder: (context) {
            fa = context.strings;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fa.exploreTitle, 'کاوش');

    late AppStrings en;
    await tester.pumpWidget(
      MaterialApp(
        locale: SupportedLocales.en,
        supportedLocales: SupportedLocales.all,
        localizationsDelegates: SupportedLocales.delegates,
        home: Builder(
          builder: (context) {
            en = context.strings;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(en.exploreTitle, 'Explore');
  });
}
