import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/platform/speech_event.dart';
import 'package:fortune_app/core/platform/speech_input.dart';
import 'package:fortune_app/features/search/presentation/widgets/fortune_search_bar.dart';
import 'package:go_router/go_router.dart';

/// A microphone that never needs a browser: the test speaks for it.
class FakeSpeech implements SpeechInput {
  FakeSpeech({this.supported = true});

  final bool supported;
  StreamController<SpeechEvent>? _controller;
  String? locale;
  bool cancelled = false;

  @override
  bool get isSupported => supported;

  @override
  Stream<SpeechEvent> listen({
    required String locale,
    required Duration silence,
  }) {
    this.locale = locale;
    cancelled = false;
    final controller = StreamController<SpeechEvent>();
    controller.onCancel = () => cancelled = true;
    _controller = controller;
    return controller.stream;
  }

  void say(SpeechEvent event) => _controller?.add(event);
}

Widget host(FakeSpeech speech) {
  final router = GoRouter(
    initialLocation: '/fortunes',
    routes: [
      GoRoute(
        path: '/fortunes',
        builder: (_, __) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FortuneSearchBar(speech: speech),
          ),
        ),
      ),
      GoRoute(
        path: '/ritual/:fortuneId',
        builder: (_, state) => Scaffold(
          body: Text('ritual-stub-${state.pathParameters['fortuneId']}'),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: SupportedLocales.fa,
    supportedLocales: SupportedLocales.all,
    localizationsDelegates: SupportedLocales.delegates,
    theme: AppTheme.dark(),
  );
}

/// Speaking is the shortest path of all (scope §3): say the name, tap the
/// fortune. Where the browser cannot listen, the microphone is never offered.
void main() {
  testWidgets('the microphone is offered only when it can hear', (
    tester,
  ) async {
    await tester.pumpWidget(host(FakeSpeech(supported: false)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('جست‌وجوی صوتی'), findsNothing);

    await tester.pumpWidget(host(FakeSpeech()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('جست‌وجوی صوتی'), findsOneWidget);
  });

  testWidgets('a spoken name fills the box and opens the fortune', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await tester.pumpWidget(host(speech));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('جست‌وجوی صوتی'));
    await tester.pumpAndSettle();
    expect(find.text('دارم گوش می‌دهم…'), findsOneWidget);
    expect(speech.locale, 'fa-IR');

    speech.say(const SpeechHeard('حاف', isFinal: true));
    await tester.pumpAndSettle();

    // The words land in the box, the index answers them, and listening ends.
    expect(find.text('حاف'), findsOneWidget);
    expect(find.text('دارم گوش می‌دهم…'), findsNothing);
    expect(speech.cancelled, isTrue);

    await tester.tap(find.text('فال حافظ'));
    await tester.pumpAndSettle();
    expect(find.text('ritual-stub-hafez'), findsOneWidget);
  });

  testWidgets('interim words are shown before the browser settles', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await tester.pumpWidget(host(speech));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('جست‌وجوی صوتی'));
    await tester.pumpAndSettle();

    speech.say(const SpeechHeard('تارو'));
    await tester.pumpAndSettle();
    expect(find.text('تاروت'), findsOneWidget);
    // Still listening: an interim reading never closes the microphone.
    expect(find.text('دارم گوش می‌دهم…'), findsOneWidget);
    expect(speech.cancelled, isFalse);
  });

  testWidgets('a refused microphone is explained, never blamed', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await tester.pumpWidget(host(speech));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('جست‌وجوی صوتی'));
    await tester.pumpAndSettle();

    speech.say(const SpeechEnded(SpeechEndReason.denied));
    await tester.pumpAndSettle();

    expect(
      find.text('اجازهٔ میکروفون داده نشد؛ از تنظیمات مرورگر روشنش کن.'),
      findsOneWidget,
    );
    expect(find.byTooltip('جست‌وجوی صوتی'), findsOneWidget);
  });

  testWidgets('silence says so, and tapping stop closes the microphone', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await tester.pumpWidget(host(speech));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('جست‌وجوی صوتی'));
    await tester.pumpAndSettle();
    speech.say(const SpeechEnded(SpeechEndReason.timeout));
    await tester.pumpAndSettle();
    expect(find.text('چیزی نشنیدم؛ دوباره بگو یا بنویس.'), findsOneWidget);

    await tester.tap(find.byTooltip('جست‌وجوی صوتی'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('توقف'));
    await tester.pumpAndSettle();

    expect(speech.cancelled, isTrue);
    expect(find.text('دارم گوش می‌دهم…'), findsNothing);
  });
}
