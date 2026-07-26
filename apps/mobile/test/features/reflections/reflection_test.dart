import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/localization/supported_locales.dart';
import 'package:fortune_app/app/theme/app_theme.dart';
import 'package:fortune_app/core/errors/app_failure.dart';
import 'package:fortune_app/core/result/result.dart';
import 'package:fortune_app/features/reflections/application/reflection_controller.dart';
import 'package:fortune_app/features/reflections/data/reflection_repository.dart';
import 'package:fortune_app/features/reflections/domain/reflection.dart';
import 'package:fortune_app/features/reflections/presentation/widgets/reflection_card.dart';

Reflection _entry({String note = 'امشب آرام‌تر بودم.'}) => Reflection(
      id: 'e1',
      readingId: 'r1',
      feeling: Feeling.calm,
      note: note,
      createdAt: DateTime(2026, 7, 26),
    );

/// Records what the card asked for, and can be told to refuse.
class FakeReflectionRepo implements ReflectionRepository {
  FakeReflectionRepo({this.existing});

  Reflection? existing;
  bool refuse = false;
  final List<Map<String, Object?>> saves = [];
  final List<Feeling> lines = [];

  @override
  Future<Result<ReflectionPage>> list({String? cursor}) async => Success(
        ReflectionPage(
          items: [if (existing != null) existing!],
          nextCursor: null,
        ),
      );

  @override
  Future<Result<Reflection?>> forReading(String readingId) async =>
      Success(existing);

  @override
  Future<Result<ReflectionLine>> line(Feeling feeling) async {
    lines.add(feeling);
    return Success(
      ReflectionLine(text: 'یک پرسش کوچک؟', tender: feeling.isTender),
    );
  }

  @override
  Future<Result<Reflection>> save({
    required String? readingId,
    required Feeling feeling,
    required String note,
  }) async {
    saves.add({'readingId': readingId, 'feeling': feeling.wire, 'note': note});
    if (refuse) {
      return const ResultFailure(
        AppFailure(kind: FailureKind.timeout, messageKey: 'errorTimeout'),
      );
    }
    existing = _entry(note: note);
    return Success(existing!);
  }

  @override
  Future<Result<String>> remove(String id) async => Success(id);
}

Widget host(FakeReflectionRepo repo) {
  return ProviderScope(
    overrides: [reflectionRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: SupportedLocales.fa,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: SupportedLocales.delegates,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: SingleChildScrollView(child: ReflectionCard(readingId: 'r1')),
      ),
    ),
  );
}

/// The diary. What is written stays written, what is refused is not pretended
/// away, and the promise of privacy is on the screen where it can be read.
void main() {
  group('payload', () {
    test('reads a complete entry', () {
      final entry = Reflection.fromJson(const {
        'id': 'e1',
        'readingId': 'r1',
        'feeling': 'longing',
        'note': 'دل‌تنگ بودم.',
        'createdAt': '2026-07-26T06:00:00.000Z',
      });

      expect(entry, isNotNull);
      expect(entry!.feeling, Feeling.longing);
      expect(entry.note, 'دل‌تنگ بودم.');
    });

    test('drops an entry it cannot trust', () {
      // An unknown feeling, a missing note, an unparseable date.
      expect(
        Reflection.fromJson(const {'id': 'e1', 'feeling': 'furious'}),
        isNull,
      );
      expect(
        Reflection.fromJson(const {
          'id': 'e1',
          'feeling': 'calm',
          'createdAt': '2026-07-26T06:00:00.000Z',
        }),
        isNull,
      );
    });

    test('a bad entry never takes the whole page down with it', () {
      final page = pageFromJson(const {
        'items': [
          {
            'id': 'e1',
            'feeling': 'calm',
            'note': 'خوب بود.',
            'createdAt': '2026-07-26T06:00:00.000Z',
          },
          {'id': 'e2', 'feeling': 'nonsense'},
          'rubbish',
        ],
        'nextCursor': 'c1',
      });

      expect(page.items, hasLength(1));
      expect(page.nextCursor, 'c1');
    });

    test('every feeling has a wire name, and two are answered gently', () {
      expect(Feeling.values.map((f) => f.wire), [
        'calm',
        'hopeful',
        'longing',
        'worried',
        'heavy',
      ]);
      expect(feelingFromWire('heavy'), Feeling.heavy);
      expect(feelingFromWire('furious'), isNull);
      expect(Feeling.values.where((f) => f.isTender), [
        Feeling.worried,
        Feeling.heavy,
      ]);
    });
  });

  group('the card', () {
    testWidgets('says plainly that the note goes nowhere', (tester) async {
      await tester.pumpWidget(host(FakeReflectionRepo()));
      await tester.pumpAndSettle();

      expect(find.text('برای خودت بنویس'), findsOneWidget);
      expect(
        find.textContaining('جایی به اشتراک گذاشته نمی‌شود'),
        findsOneWidget,
      );
    });

    testWidgets('asks for a line only once a feeling is chosen', (
      tester,
    ) async {
      final repo = FakeReflectionRepo();
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();
      expect(repo.lines, isEmpty);

      await tester.tap(find.text('آرام'));
      await tester.pumpAndSettle();

      expect(repo.lines, [Feeling.calm]);
      expect(find.text('یک پرسش کوچک؟'), findsOneWidget);
    });

    testWidgets('sends what was chosen, and says so once it is kept', (
      tester,
    ) async {
      final repo = FakeReflectionRepo();
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('گرفته'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  امروز سنگین بود.  ');
      await tester.tap(find.text('ثبت'));
      await tester.pumpAndSettle();

      expect(repo.saves, [
        {'readingId': 'r1', 'feeling': 'heavy', 'note': 'امروز سنگین بود.'},
      ]);
      expect(find.text('ثبت شد'), findsOneWidget);
    });

    testWidgets('never claims to have kept something it did not', (
      tester,
    ) async {
      final repo = FakeReflectionRepo()..refuse = true;
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('آرام'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'چیزی');
      await tester.tap(find.text('ثبت'));
      await tester.pumpAndSettle();

      expect(repo.saves, hasLength(1));
      expect(find.text('ثبت شد'), findsNothing);
      expect(find.text('ثبت'), findsOneWidget);
    });

    testWidgets('opens with what was written before', (tester) async {
      final repo = FakeReflectionRepo(existing: _entry());
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();

      expect(find.text('امشب آرام‌تر بودم.'), findsOneWidget);
      // The feeling came back with it, so its line was asked for.
      expect(repo.lines, [Feeling.calm]);
    });
  });
}
