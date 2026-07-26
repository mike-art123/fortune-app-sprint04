import '../../../app/routing/fortune_destinations.dart';
import '../../fortunes/domain/fortune_registry.dart';
import 'fa_text.dart';

/// Words people actually use for a fortune that its own title never says.
/// Kept short and true — an alias is a second real name, not a keyword farm.
const Map<String, List<String>> kFortuneAliases = {
  'hafez': ['حافظ', 'دیوان', 'تفال', 'شعر', 'لسان الغیب'],
  'tarot': ['تاروت', 'کارت', 'آرکانا'],
  'dream': ['خواب', 'رویا', 'تعبیر خواب', 'خواب دیدم'],
  'love': ['عشق', 'دل', 'رابطه', 'معشوق'],
  'coffee': ['قهوه', 'فنجان', 'ترک'],
  'abjad': ['ابجد', 'حروف', 'اعداد'],
  'marriage': ['ازدواج', 'عروسی', 'خواستگاری'],
  'child': ['فرزند', 'بچه', 'بارداری'],
  'friendship': ['دوستی', 'رفاقت', 'دوست'],
  'separation': ['جدایی', 'قهر', 'کات'],
  'reconcile': ['آشتی', 'بازگشت', 'برگشتن'],
  'name': ['اسم', 'نام'],
  'job': ['شغل', 'کار', 'استخدام', 'شغلی'],
  'money': ['مالی', 'پول', 'ثروت', 'درآمد'],
  'travel': ['سفر', 'مهاجرت', 'مسافرت'],
  'future': ['آینده', 'سرنوشت'],
  'message': ['پیام', 'خبر'],
  'intention': ['نیت', 'قصد'],
  'yesno': ['بله یا خیر', 'اره یا نه', 'بله', 'خیر', 'جواب سریع'],
  'luckynumber': ['عدد شانس', 'شماره شانس', 'عدد'],
  'luckycolor': ['رنگ شانس', 'رنگ'],
  'luckystone': ['سنگ شانس', 'سنگ', 'نگین'],
  'luckyflower': ['گل شانس', 'گل'],
  'dailytalisman': ['طلسم', 'حرز', 'انرژی'],
  'lots': ['قرعه', 'شانس'],
  'birthmonth': ['ماه تولد', 'طالع', 'برج'],
  'daily': ['روزانه', 'امروز', 'فال امروز'],
  'universe': ['کائنات', 'جهان', 'هستی'],
  'tea': ['چای', 'برگ چای'],
  'candle': ['شمع', 'نور'],
  'mirror': ['آینه'],
  'lenormand': ['لنورمان', 'لنرماند'],
  'rune': ['رون', 'رونز', 'حروف باستان'],
  'cards': ['کارتی', 'اوراکل', 'کارت‌ها'],
  'quran': ['قرآن', 'استخاره', 'استخاره قرآن', 'کتاب'],
  'tasbih': ['تسبیح', 'دانه'],
  'angel': ['فرشته', 'فرشتگان', 'ملائک'],
  'spiritanimal': ['حیوان روح', 'توتم', 'حیوان'],
  'meditation': ['مدیتیشن', 'مراقبه', 'تمرکز'],
};

/// One searchable fortune: what it is called, and every folded form that
/// should reach it.
class FortuneSearchEntry {
  const FortuneSearchEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isOpenable,
    required this.terms,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Whether tapping this result actually leads somewhere (a ritual or a
  /// guide). The label and the ranking both read this, never raw availability,
  /// so a guided fortune is never announced as «به‌زودی».
  final bool isOpenable;

  /// Normalized terms: the whole title, its words, the subtitle's words and
  /// the curated aliases.
  final List<String> terms;
}

class FortuneSearchResult {
  const FortuneSearchResult({required this.entry, required this.score});

  final FortuneSearchEntry entry;
  final int score;
}

/// Deterministic, offline fortune search (scope §2, first stage of the
/// hybrid pipeline): exact → prefix → contains → typo-tolerant. No network,
/// no model — the answer to «فال حافظ» must be instant and always the same.
abstract final class FortuneSearch {
  static final List<FortuneSearchEntry> index = _buildIndex();

  static List<FortuneSearchResult> query(String raw, {int limit = 6}) {
    final normalized = faNormalize(raw);
    if (normalized.isEmpty) return const [];

    final results = <FortuneSearchResult>[];
    for (final entry in index) {
      final score = _entryScore(entry, normalized);
      if (score > 0) {
        results.add(FortuneSearchResult(entry: entry, score: score));
      }
    }
    results.sort(_byRelevance);
    return results.take(limit).toList(growable: false);
  }

  static List<FortuneSearchEntry> _buildIndex() {
    return FortuneRegistry.all.map((fortune) {
      final title = fortune.title.fa;
      final subtitle = fortune.subtitle.fa;
      final terms = <String>{
        faNormalize(title),
        ...faTokens(title),
        ...faTokens(subtitle),
        for (final alias in kFortuneAliases[fortune.id] ?? const <String>[])
          faNormalize(alias),
        fortune.id,
      }..removeWhere((term) => term.isEmpty);
      return FortuneSearchEntry(
        id: fortune.id,
        title: title,
        subtitle: subtitle,
        isOpenable: FortuneDestinations.pathFor(fortune.id) != null,
        terms: terms.toList(growable: false),
      );
    }).toList(growable: false);
  }

  static int _entryScore(FortuneSearchEntry entry, String query) {
    var best = 0;
    for (final term in entry.terms) {
      final score = _termScore(term, query);
      if (score > best) best = score;
    }
    return best;
  }

  static int _termScore(String term, String query) {
    if (term == query) return 1000;
    if (term.startsWith(query)) {
      final overshoot = term.length - query.length;
      return 800 - (overshoot > 100 ? 100 : overshoot);
    }
    if (term.contains(query)) return 600;

    // A typo still deserves its fortune, but only a typo: short queries get
    // no forgiveness at all, so «گل» can never become «دل».
    final ceiling = query.length <= 3 ? 0 : (query.length <= 6 ? 1 : 2);
    if (ceiling == 0) return 0;
    final distance = faEditDistance(term, query, ceiling: ceiling);
    if (distance > ceiling) return 0;
    return 500 - distance * 60;
  }

  static int _byRelevance(FortuneSearchResult a, FortuneSearchResult b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    if (a.entry.isOpenable != b.entry.isOpenable) {
      return a.entry.isOpenable ? -1 : 1;
    }
    final byLength = a.entry.title.length.compareTo(b.entry.title.length);
    if (byLength != 0) return byLength;
    return a.entry.id.compareTo(b.entry.id);
  }
}
