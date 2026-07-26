/// Persian-aware text folding for search (scope §2).
///
/// Someone may type the Arabic ي or ك, paste a نیم‌فاصله, use Persian digits
/// or leave a diacritic behind. None of that changes what they meant, so both
/// the index and the query are folded onto one canonical form before matching
/// — «فال حافظ»، «فال ‌حافظ» and «فال حافظ» must all find the same fortune.
library;

/// Arabic letter shapes folded onto their single Persian form.
const Map<String, String> _letters = {
  'ي': 'ی',
  'ى': 'ی',
  'ئ': 'ی',
  'ك': 'ک',
  'ة': 'ه',
  'ۀ': 'ه',
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ٱ': 'ا',
  'ؤ': 'و',
};

/// Persian and Arabic-Indic digits folded onto ASCII.
const Map<String, String> _digits = {
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
};

/// Tashkeel, the hamza marks, the superscript alef and the decorative tatweel
/// carry no meaning for matching (U+064B–U+065F, U+0670, U+0640).
final RegExp _marks = RegExp('[ً-ٰٟـ]');

/// Anything that is not a Persian letter, a latin letter or a digit is a word
/// boundary — punctuation, ZWNJ (نیم‌فاصله), bidi marks, emoji.
final RegExp _boundaries = RegExp('[^0-9a-zء-ی]');

final RegExp _spaceRuns = RegExp(r'\s+');

/// The canonical form used by the search index and by every query.
String faNormalize(String input) {
  var text = input.toLowerCase();
  for (final fold in _letters.entries) {
    text = text.replaceAll(fold.key, fold.value);
  }
  for (final fold in _digits.entries) {
    text = text.replaceAll(fold.key, fold.value);
  }
  return text
      .replaceAll(_marks, '')
      .replaceAll(_boundaries, ' ')
      .replaceAll(_spaceRuns, ' ')
      .trim();
}

/// Normalized words — the unit both the index and the query match on.
List<String> faTokens(String input) {
  final normalized = faNormalize(input);
  if (normalized.isEmpty) return const [];
  return normalized.split(' ');
}

/// Edit distance, bounded: a typo should still find the fortune, but a
/// different word must not. Returns [ceiling] + 1 as soon as it is exceeded,
/// so long strings cost little.
int faEditDistance(String a, String b, {required int ceiling}) {
  if (a == b) return 0;
  if ((a.length - b.length).abs() > ceiling) return ceiling + 1;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var rowBest = current[0];
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final best = substitution < deletion ? substitution : deletion;
      current[j] = best < insertion ? best : insertion;
      if (current[j] < rowBest) rowBest = current[j];
    }
    if (rowBest > ceiling) return ceiling + 1;
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}
