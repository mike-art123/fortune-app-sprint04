import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/design_system/components/fortune_error_state.dart';

void main() {
  testWidgets('error state offers retry and reassurance', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: FortuneErrorState(
              message: 'مشکلی پیش آمد',
              reassurance: 'اطلاعاتت محفوظ است.',
              retryLabel: 'دوباره تلاش کن',
              onRetry: () => retried++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('اطلاعاتت محفوظ است.'), findsOneWidget);
    await tester.tap(find.text('دوباره تلاش کن'));
    expect(retried, 1);
  });
}
