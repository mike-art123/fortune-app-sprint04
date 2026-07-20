import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/design_system/components/fortune_button.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(FortuneButton(label: 'ادامه', onPressed: () => taps++)),
    );

    expect(find.text('ادامه'), findsOneWidget);
    await tester.tap(find.byType(FortuneButton));
    expect(taps, 1);
  });

  testWidgets('disabled button does not fire', (tester) async {
    await tester.pumpWidget(_host(const FortuneButton(label: 'ادامه')));
    await tester.tap(find.byType(FortuneButton));
    expect(tester.takeException(), isNull);
  });

  testWidgets('label stays visible while loading', (tester) async {
    await tester.pumpWidget(
      _host(FortuneButton(label: 'ادامه', isLoading: true, onPressed: () {})),
    );
    expect(find.text('ادامه'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
