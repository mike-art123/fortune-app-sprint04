import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_app/app/routing/fortune_destinations.dart';
import 'package:fortune_app/features/recommendations/domain/next_fortunes.dart';

ReadingMoment moment(String id, int hour, {int day = 1}) {
  return ReadingMoment(fortuneId: id, at: DateTime(2026, 7, day, hour));
}

/// Where to go after a reading (scope §4, §5). Everything is derived from the
/// reader's own history, every card says why it is there, and nothing is
/// suggested that cannot be opened.
void main() {
  final night = DateTime(2026, 7, 26, 22);

  test('never suggests the fortune just read', () {
    final out = nextFortunes(justRead: 'hafez', history: const [], now: night);
    expect(out.map((n) => n.fortuneId), isNot(contains('hafez')));
  });

  test('gives at most three, and never a dead end', () {
    final out = nextFortunes(justRead: 'hafez', history: const [], now: night);
    expect(out.length, 3);
    for (final next in out) {
      expect(FortuneDestinations.pathFor(next.fortuneId), isNotNull);
      expect(next.reason, isNotEmpty);
      expect(next.title, isNotEmpty);
    }
  });

  test('never repeats itself inside one strip', () {
    final out = nextFortunes(
      justRead: 'hafez',
      history: [moment('tarot', 22), moment('dream', 21)],
      now: night,
    );
    expect(out.map((n) => n.fortuneId).toSet().length, out.length);
  });

  test('starts with the family of what was just read', () {
    final out = nextFortunes(
      justRead: 'marriage',
      history: const [],
      now: night,
    );
    // «فال ازدواج» lives in the love-and-bonds group.
    expect(out.first.fortuneId, isIn(['child', 'friendship', 'separation']));
    expect(out.first.reason, contains('هم‌خانواده'));
  });

  test('a habit at this hour is offered, and named as one', () {
    final out = nextFortunes(
      justRead: 'hafez',
      // Read at night, twice: that is a habit. The daytime one is not.
      history: [
        moment('dream', 22, day: 1),
        moment('dream', 23, day: 2),
        moment('money', 12, day: 3),
      ],
      now: night,
    );
    final dream = out.where((n) => n.fortuneId == 'dream');
    expect(dream, isNotEmpty);
    expect(dream.first.reason, contains('شب‌ها'));
  });

  test('one reading at an hour is not yet a habit', () {
    final out = nextFortunes(
      justRead: 'hafez',
      history: [moment('dream', 22)],
      now: night,
    );
    final dream = out.where((n) => n.fortuneId == 'dream');
    // It may still appear as something untried — but never as a habit.
    for (final next in dream) {
      expect(next.reason, isNot(contains('شب‌ها')));
    }
  });

  test('something never tried is offered as exactly that', () {
    final out = nextFortunes(justRead: 'hafez', history: const [], now: night);
    expect(
      out.any((n) => n.reason == 'هنوز امتحانش نکرده‌ای'),
      isTrue,
    );
  });

  test('the same reader, the same hour, the same answer', () {
    final history = [moment('dream', 22, day: 1), moment('dream', 23, day: 2)];
    final first = nextFortunes(justRead: 'hafez', history: history, now: night);
    final again = nextFortunes(justRead: 'hafez', history: history, now: night);
    expect(
      first.map((n) => n.fortuneId).toList(),
      again.map((n) => n.fortuneId).toList(),
    );
  });

  test('the day is split into four named parts', () {
    expect(dayPartOf(DateTime(2026, 7, 26, 7)), DayPart.morning);
    expect(dayPartOf(DateTime(2026, 7, 26, 13)), DayPart.noon);
    expect(dayPartOf(DateTime(2026, 7, 26, 18)), DayPart.evening);
    expect(dayPartOf(DateTime(2026, 7, 26, 2)), DayPart.night);
  });

  test('a reader with no history still gets somewhere to go', () {
    for (final id in ['hafez', 'tarot', 'dream', 'love']) {
      final out = nextFortunes(justRead: id, history: const [], now: night);
      expect(out, isNotEmpty, reason: 'after $id there must be a next step');
    }
  });
}
