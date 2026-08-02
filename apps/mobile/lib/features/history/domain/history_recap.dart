import 'package:flutter/widgets.dart';

import '../../fortunes/domain/fortune_registry.dart';
import 'history_summary.dart';

/// The «نگاهی به گذشته» sentence, written here rather than fetched.
///
/// The summary endpoint builds its paragraph from Persian templates and is
/// never told which language the reader chose, so an English screen carried a
/// Persian paragraph. Everything that paragraph says is arithmetic this side
/// already holds — how many readings, how many the period before, which
/// fortune came up most — so it can simply be said again in the reader's own
/// words, with no call to the server and no change to it.
///
/// Persian returns null on purpose. There the server's sentence is already
/// right, it is warmer than anything assembled from parts, and it knows two
/// things this side never receives: the time of day most readings happened,
/// and which fortunes were tried for the first time. Null keeps every Persian
/// reader — which is every web and Play reader today — on the exact text they
/// see now.
String? recapFor(HistorySummary summary, Locale locale) {
  final lang = locale.languageCode;
  if (lang == 'fa') return null;

  final days = _days(summary.range);
  if (summary.total == 0) return _nothing(lang, days);

  final lines = <String>[_taken(lang, days, summary)];
  final top = _favourite(summary);
  if (top != null) {
    // Same table the cards and the tally chips read, so one fortune is never
    // named two ways on one screen.
    final known = FortuneRegistry.byId(top.fortuneId);
    final name = known?.title.resolve(locale) ?? top.title;
    lines.add(_mostOften(lang, name, top.count));
  }
  return lines.join(' ');
}

int _days(SummaryRange range) => switch (range) {
      SummaryRange.last7 => 7,
      SummaryRange.last30 => 30,
      SummaryRange.last90 => 90,
    };

/// The fortune opened most — and only when "most" means something. Reaching
/// for one thing a single time is not a habit worth naming back at someone.
FortuneTally? _favourite(HistorySummary summary) {
  FortuneTally? best;
  for (final tally in summary.byFortune) {
    if (best == null || tally.count > best.count) best = tally;
  }
  if (best == null || best.count < 2) return null;
  return best;
}

String _nothing(String lang, int days) => switch (lang) {
      'ar' => 'لم تأخذ أي فأل في آخر $days يوماً.',
      'tr' => 'Son $days günde hiç fal bakmadın.',
      _ => "You haven't taken a fortune in the last $days days.",
    };

/// How many, and how that sits against the stretch before it. The comparison
/// is only drawn when there was a previous stretch to draw it against.
String _taken(String lang, int days, HistorySummary summary) => switch (lang) {
      'ar' => _takenAr(days, summary),
      'tr' => _takenTr(days, summary),
      _ => _takenEn(days, summary),
    };

String _takenEn(int days, HistorySummary summary) {
  final n = summary.total;
  final head = 'You took $n ${n == 1 ? 'fortune' : 'fortunes'} '
      'in the last $days days';
  final delta = n - summary.previousTotal;
  if (summary.previousTotal == 0) return '$head.';
  if (delta > 0) return '$head — $delta more than the period before.';
  if (delta < 0) return '$head — ${-delta} fewer than the period before.';
  return '$head — exactly as many as the period before.';
}

String _takenTr(int days, HistorySummary summary) {
  final n = summary.total;
  final head = 'Son $days günde $n fal baktın';
  final delta = n - summary.previousTotal;
  if (summary.previousTotal == 0) return '$head.';
  if (delta > 0) return '$head; önceki döneme göre $delta fazla.';
  if (delta < 0) return '$head; önceki döneme göre ${-delta} az.';
  return '$head; önceki dönemle tam olarak aynı.';
}

/// «فؤول» is the plural the app's own Arabic already uses for these, so the
/// recap speaks the way the rest of the screen does.
String _takenAr(int days, HistorySummary summary) {
  final n = summary.total;
  final counted = n == 1 ? 'فألاً واحداً' : '$n فؤول';
  final head = 'أخذت $counted في آخر $days يوماً';
  final delta = n - summary.previousTotal;
  if (summary.previousTotal == 0) return '$head.';
  if (delta > 0) return '$head، أكثر من الفترة السابقة بـ $delta.';
  if (delta < 0) return '$head، أقل من الفترة السابقة بـ ${-delta}.';
  return '$head، مثل الفترة السابقة تماماً.';
}

String _mostOften(String lang, String name, int count) => switch (lang) {
      'ar' => 'الأكثر بينها: $name ($count).',
      'tr' => 'En çok baktığın: $name ($count kez).',
      _ => 'You reached for $name most — $count times.',
    };
