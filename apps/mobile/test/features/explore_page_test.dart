import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/features/explore/presentation/pages/explore_page.dart';
import 'package:fortune_app/features/explore/presentation/widgets/fortune_grid_card.dart';
import 'package:fortune_app/features/fortunes/domain/fortune_registry.dart';

Widget host() => ProviderScope(
      child: MaterialApp(
        locale: SupportedLocales.fa,
        supportedLocales: SupportedLocales.all,
        localizationsDelegates: SupportedLocales.delegates,
        theme: AppTheme.dark(),
        home: const ExplorePage(),
      ),
    );

void main() {
  testWidgets('explore renders one card per registry entry', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(
      find.byType(FortuneGridCard),
      findsNWidgets(FortuneRegistry.all.length),
    );
  });

  testWidgets('explore shows Persian titles from the registry', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('فال حافظ'), findsOneWidget);
    expect(find.text('تعبیر خواب'), findsOneWidget);
  });

  testWidgets('soon fortunes carry the coming-soon label', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final soonCount = FortuneRegistry.all.where((f) => !f.isAvailable).length;
    expect(find.text('به‌زودی'), findsNWidgets(soonCount));
  });
}
