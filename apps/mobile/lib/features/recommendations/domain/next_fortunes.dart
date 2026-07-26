import '../../../app/routing/fortune_destinations.dart';
import '../../fortunes/domain/fortune_catalog.dart';
import '../../fortunes/domain/fortune_registry.dart';

/// One suggestion, and the reason it is being made (scope §5).
///
/// A suggestion without a reason is just an advertisement. Every card here
/// says, in one line, what about *this reader* led to it.
class NextFortune {
  const NextFortune({
    required this.fortuneId,
    required this.title,
    required this.reason,
  });

  final String fortuneId;
  final String title;
  final String reason;
}

/// A past reading, reduced to what a suggestion may look at: which fortune,
/// and when. Never the text — the words of a reading are nobody's input to
/// anything else.
class ReadingMoment {
  const ReadingMoment({required this.fortuneId, required this.at});

  final String fortuneId;
  final DateTime at;
}

/// The four parts of a day this app recognises, in Persian terms.
enum DayPart { morning, noon, evening, night }

DayPart dayPartOf(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 11) return DayPart.morning;
  if (hour >= 11 && hour < 16) return DayPart.noon;
  if (hour >= 16 && hour < 20) return DayPart.evening;
  return DayPart.night;
}

const Map<DayPart, String> _dayPartFa = {
  DayPart.morning: 'صبح‌ها',
  DayPart.noon: 'ظهرها',
  DayPart.evening: 'عصرها',
  DayPart.night: 'شب‌ها',
};

/// How far back «recently» reaches when avoiding a repeat.
const int _recentWindow = 8;

/// Where to go after a reading (scope §4 and §5).
///
/// Everything below is derived from the reader's own history — no profile
/// table, no second source of truth, nothing about anyone else. Deleting a
/// reading therefore also deletes its influence, with no cleanup to remember.
///
/// The order is deliberate: what belongs with what was just read, then what
/// this person actually tends to read at this hour, then something they have
/// never tried. At most [limit] cards, each openable, each explained.
List<NextFortune> nextFortunes({
  required String justRead,
  required List<ReadingMoment> history,
  required DateTime now,
  int limit = 3,
}) {
  final picked = <String>{justRead};
  final out = <NextFortune>[];

  final recent = history.take(_recentWindow).map((m) => m.fortuneId).toSet();
  final known = history.map((m) => m.fortuneId).toSet();
  final family = _familyOf(justRead);

  bool add(String id, String reason) {
    if (out.length >= limit) return false;
    if (picked.contains(id)) return false;
    if (FortuneDestinations.pathFor(id) == null) return false;
    final title = FortuneRegistry.byId(id)?.title.fa;
    if (title == null) return false;
    picked.add(id);
    out.add(NextFortune(fortuneId: id, title: title, reason: reason));
    return true;
  }

  // One card per kind of reason first, so the strip says three different
  // things rather than the same thing three times.

  // 1. Its own family: the theme the reader is already inside.
  for (final id in family) {
    if (recent.contains(id)) continue;
    if (add(id, _familyReason)) break;
  }

  // 2. Their own habit at this hour, if they have one.
  final part = dayPartOf(now);
  final habit = _habitAt(history, part);
  if (habit != null) {
    add(habit, '${_dayPartFa[part]} بیشتر همین را می‌خوانی');
  }

  // 3. Something never tried, in the order the catalog presents fortunes.
  for (final id in _catalogOrder()) {
    if (known.contains(id)) continue;
    if (add(id, _untriedReason)) break;
  }

  // Still short? Widen: more of the family (even if read recently), then
  // anything else the catalog offers.
  for (final id in family) {
    add(id, _familyReason);
  }
  for (final id in _catalogOrder()) {
    add(id, known.contains(id) ? _againReason : _untriedReason);
  }

  return out;
}

const String _familyReason = 'هم‌خانوادهٔ چیزی که همین حالا خواندی';
const String _untriedReason = 'هنوز امتحانش نکرده‌ای';
const String _againReason = 'قبلاً خوانده‌ای؛ شاید دوباره';

/// The other fortunes in the same catalog group, in catalog order.
List<String> _familyOf(String fortuneId) {
  for (final group in FortuneCatalog.groups) {
    final ids = group.items.map((item) => item.$1).toList(growable: false);
    if (ids.contains(fortuneId)) {
      return ids.where((id) => id != fortuneId).toList(growable: false);
    }
  }
  return const [];
}

/// The fortune this reader opens most often in this part of the day. Needs at
/// least two readings to count as a habit — once is not a pattern.
String? _habitAt(List<ReadingMoment> history, DayPart part) {
  final counts = <String, int>{};
  for (final moment in history) {
    if (dayPartOf(moment.at) != part) continue;
    counts[moment.fortuneId] = (counts[moment.fortuneId] ?? 0) + 1;
  }

  String? best;
  var bestCount = 1;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

List<String> _catalogOrder() {
  return [
    for (final group in FortuneCatalog.groups)
      for (final item in group.items) item.$1,
  ];
}
