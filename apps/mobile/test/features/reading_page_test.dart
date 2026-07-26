import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/design_system/components/fortune_button.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/features/history/application/history_controller.dart';
import 'package:fortune_app/features/profile/application/profile_controller.dart';
import 'package:fortune_app/features/profile/domain/user_profile.dart';
import 'package:fortune_app/features/reading/domain/reading.dart';
import 'package:fortune_app/features/reading/presentation/pages/reading_page.dart';
import 'package:go_router/go_router.dart';

/// Share reads the profile for the privacy strip; this stub keeps the page
/// independent of startup/auth in tests.
class _NoProfile extends ProfileController {
  @override
  Future<UserProfile?> build() async => null;
}

class _NamedProfile extends ProfileController {
  @override
  Future<UserProfile?> build() async => const UserProfile(
        displayName: 'علی',
        birthMonth: 'MEHR',
        onboardingCompleted: true,
      );
}

Widget host(
  Reading? reading, {
  List<Override> overrides = const [],
  ProfileController Function() profile = _NoProfile.new,
}) {
  final router = GoRouter(
    initialLocation: '/reading',
    routes: [
      GoRoute(
        path: '/reading',
        builder: (_, __) => ReadingPage(readingId: 'clx1', reading: reading),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(profile),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
    ),
  );
}

Reading _reading() => Reading(
      id: 'clx1',
      fortuneId: 'hafez',
      title: 'پیامی از دیوان',
      text: 'این روزها آرام‌تر از آن‌اند که به چشم می‌آیند.',
      createdAt: DateTime(2026, 1, 7),
    );

void main() {
  testWidgets('renders title, reading text, and Persian date', (tester) async {
    await tester.pumpWidget(host(_reading()));
    await tester.pumpAndSettle();

    expect(find.text('پیامی از دیوان'), findsOneWidget);
    expect(find.textContaining('آرام‌تر'), findsOneWidget);
    expect(find.text('۲۰۲۶/۰۱/۰۷'), findsOneWidget);
  });

  testWidgets('save confirms history; share copies the reading', (
    tester,
  ) async {
    // The real clipboard channel has no handler under flutter_test; without a
    // mock, Clipboard.setData never completes and the share flow stalls.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<Object?, Object?>;
          copied.add(args['text']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(host(_reading()));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FortuneButton>(
      find.widgetWithText(FortuneButton, 'ذخیره'),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.text('ذخیره'));
    await tester.pump();
    expect(find.text('در تاریخچه‌ات ماند.'), findsOneWidget);

    await tester.tap(find.text('اشتراک‌گذاری'));
    await tester.pumpAndSettle();
    expect(find.text('متنِ فال کپی شد؛ هرجا خواستی بفرست.'), findsOneWidget);
    expect(copied.single, contains('پیامی از دیوان'));
  });

  testWidgets('share hides the name by default (privacy, scope §16)', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<Object?, Object?>;
          copied.add(args['text']! as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final named = Reading(
      id: 'clx1',
      fortuneId: 'hafez',
      title: 'پیامی از دیوان',
      text: 'علی، این روزها آرام‌تر از آن‌اند که به چشم می‌آیند.',
      createdAt: DateTime(2026, 1, 7),
    );
    await tester.pumpWidget(host(named, profile: _NamedProfile.new));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اشتراک‌گذاری'));
    await tester.pumpAndSettle();

    // On screen the greeting is personal; what leaves the app is not.
    expect(copied.single, isNot(contains('علی،')));
    expect(copied.single, contains('این روزها آرام‌تر'));
  });

  testWidgets('cold deep link fetches the reading by id', (tester) async {
    await tester.pumpWidget(
      host(
        null,
        overrides: [
          readingByIdProvider('clx1').overrideWith((ref) async => _reading()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('پیامی از دیوان'), findsOneWidget);
  });

  testWidgets('a failed fetch shows honest recovery, never a blank page', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        null,
        overrides: [
          readingByIdProvider('clx1').overrideWith(
            (ref) async => throw const AppFailure(
              kind: FailureKind.notFound,
              messageKey: 'failure.notFound',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('برای دیدنِ خوانش، از مسیرِ آیین وارد شو.'),
      findsOneWidget,
    );
  });
}
