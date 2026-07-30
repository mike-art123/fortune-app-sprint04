import 'dart:ui' show Locale;

import '../../../app/routing/app_routes.dart';
import '../../fortunes/domain/fortune_registry.dart';
import '../../../shared/models/localized_text.dart';
import 'fa_text.dart';
import 'search_action.dart';

/// A whole sentence, resolved (scope §2, second stage of the pipeline).
///
/// People do not only type names — they say «برام یه فال بگیر» or
/// «تاریخچه‌ام رو ببین». The lexical index answers names; this layer answers
/// sentences, with rules instead of a model: no network, no cost, same answer
/// every time. Only fixed routes and registry ids can be reached, so a
/// sentence can never invent a destination.
class SearchIntentMatch {
  const SearchIntentMatch({
    required this.label,
    required this.hint,
    required this.action,
  });

  /// What will open, named the way the app names it.
  final String label;

  /// One calm line under the label, so nothing opens by surprise.
  final String hint;

  final SearchAction action;
}

/// A screen search may open, named the way the app names it. One table, read
/// by the rules below and by anything else that answers a search — so two
/// stages can never call the same screen by two different names.
class AppScreenTarget {
  const AppScreenTarget({
    required this.path,
    required this.label,
    required this.hint,
  });

  final String path;
  final LocalizedText label;
  final LocalizedText hint;
}

const Map<String, AppScreenTarget> kSearchScreens = {
  'history': AppScreenTarget(
    path: AppRoutes.historyPath,
    label: LocalizedText(
      fa: 'تاریخچهٔ فال‌ها',
      en: 'Fortune history',
      ar: 'سجلّ الفؤول',
      tr: 'Fal geçmişi',
    ),
    hint: LocalizedText(
      fa: 'هرچه تا امروز خوانده‌ای',
      en: 'Everything read so far',
      ar: 'كل ما قرأته حتى اليوم',
      tr: 'Bugüne dek okudukların',
    ),
  ),
  'profile': AppScreenTarget(
    path: AppRoutes.profilePath,
    label: LocalizedText(
      fa: 'پروفایل من',
      en: 'My profile',
      ar: 'ملفي الشخصي',
      tr: 'Profilim',
    ),
    hint: LocalizedText(
      fa: 'نام و ماه تولدت',
      en: 'Your name and birth month',
      ar: 'اسمك وشهر ميلادك',
      tr: 'Adın ve doğum ayın',
    ),
  ),
  'fortunes': AppScreenTarget(
    path: AppRoutes.allFortunesPath,
    label: LocalizedText(
      fa: 'همه فال‌ها',
      en: 'All fortunes',
      ar: 'كل الفؤول',
      tr: 'Tüm fallar',
    ),
    hint: LocalizedText(
      fa: 'فهرست کامل، دسته‌بندی‌شده',
      en: 'The full list, by category',
      ar: 'القائمة الكاملة مصنّفة',
      tr: 'Kategorilere göre tam liste',
    ),
  ),
};

/// An intent that opens a fixed screen, named by its key in [kSearchScreens].
class _RouteRule {
  const _RouteRule({required this.triggers, required this.screen});

  final List<String> triggers;
  final String screen;
}

/// An intent that opens a fortune. The id still goes through the shared
/// destination map, so an intent can never outrank availability.
class _FortuneRule {
  const _FortuneRule({
    required this.triggers,
    required this.fortuneId,
    required this.hint,
  });

  final List<String> triggers;
  final String fortuneId;
  final LocalizedText hint;
}

const List<_RouteRule> _routeRules = [
  _RouteRule(
    triggers: ['تاریخچه', 'سابقه', 'فال های قبلی', 'قبلی', 'گذشته'],
    screen: 'history',
  ),
  // «اسمم عوض» carries no را/رو, so both spellings of the sentence match.
  _RouteRule(
    triggers: ['پروفایل', 'حساب من', 'تنظیمات', 'اسمم عوض'],
    screen: 'profile',
  ),
  _RouteRule(
    triggers: ['همه فال ها', 'لیست فال ها', 'فهرست', 'چی داری', 'چه فالی داری'],
    screen: 'fortunes',
  ),
];

/// Sentences that name no fortune but clearly want one. Only phrasings the
/// index cannot already answer live here — an alias is not repeated as a rule.
const List<_FortuneRule> _fortuneRules = [
  _FortuneRule(
    triggers: ['فال بگیر', 'فالم بگو', 'یه فال', 'امروز چی', 'امروزم چطور'],
    fortuneId: 'daily',
    hint: LocalizedText(
      fa: 'فال امروزت',
      en: 'Your fortune for today',
      ar: 'فأل يومك',
      tr: 'Bugünün falın',
    ),
  ),
  _FortuneRule(
    triggers: ['جواب کوتاه', 'سوال بله'],
    fortuneId: 'yesno',
    hint: LocalizedText(
      fa: 'یک پاسخ کوتاه',
      en: 'One short answer',
      ar: 'إجابة قصيرة',
      tr: 'Kısa bir yanıt',
    ),
  ),
  _FortuneRule(
    triggers: ['خوابم تعبیر', 'تعبیر کن'],
    fortuneId: 'dream',
    hint: LocalizedText(
      fa: 'خوابت را می‌خوانیم',
      en: 'We read your dream',
      ar: 'نقرأ حلمك',
      tr: 'Rüyanı yorumluyoruz',
    ),
  ),
];

abstract final class SearchIntents {
  /// The best intent for a sentence, or null when nothing is certain enough.
  /// The most specific trigger wins (most words matched), and a tie keeps the
  /// order written above — so the same sentence always lands the same place.
  static SearchIntentMatch? match(
    String raw, {
    Locale locale = const Locale('fa'),
  }) {
    final tokens = faTokens(raw).toSet();
    if (tokens.isEmpty) return null;

    SearchIntentMatch? best;
    var bestScore = 0;

    for (final rule in _routeRules) {
      final score = _score(rule.triggers, tokens);
      if (score <= bestScore) continue;
      final match = SearchIntents.forScreen(rule.screen, locale: locale);
      if (match == null) continue;
      bestScore = score;
      best = match;
    }

    for (final rule in _fortuneRules) {
      final score = _score(rule.triggers, tokens);
      if (score <= bestScore) continue;
      final match = SearchIntents.forFortune(rule.fortuneId, locale: locale);
      if (match == null) continue;
      bestScore = score;
      // The rule's own hint says why this sentence leads here; the registry
      // subtitle is kept for answers that arrive without one.
      best = SearchIntentMatch(
        label: match.label,
        hint: rule.hint.resolve(locale),
        action: match.action,
      );
    }

    return best;
  }

  /// A screen by its key, or null when the key is not one we own. Every stage
  /// that wants to open a screen — the rules here, or an answer from the
  /// server — goes through this, so no stage can name a screen we do not have.
  static SearchIntentMatch? forScreen(
    String screen, {
    Locale locale = const Locale('fa'),
  }) {
    final target = kSearchScreens[screen];
    if (target == null) return null;
    final label = target.label.resolve(locale);
    return SearchIntentMatch(
      label: label,
      hint: target.hint.resolve(locale),
      action: OpenDestinationAction(path: target.path, label: label),
    );
  }

  /// A fortune by its id, resolved through the shared destination map so an
  /// answer can never outrank availability, and named by the registry so the
  /// row reads exactly like every other row.
  static SearchIntentMatch? forFortune(
    String fortuneId, {
    Locale locale = const Locale('fa'),
  }) {
    final action = SearchActions.forFortune(fortuneId);
    final fortune = FortuneRegistry.byId(fortuneId);
    if (action is! OpenFortuneAction || fortune == null) return null;
    return SearchIntentMatch(
      label: fortune.title.resolve(locale),
      hint: fortune.subtitle.resolve(locale),
      action: action,
    );
  }

  /// How many words of the strongest matching trigger the sentence contains.
  /// Every word must be present, so «فال بگیر» never fires on «فال حافظ».
  static int _score(List<String> triggers, Set<String> tokens) {
    var best = 0;
    for (final trigger in triggers) {
      final needed = faTokens(trigger);
      if (needed.isEmpty || needed.length <= best) continue;
      if (needed.every((word) => _contains(tokens, word))) best = needed.length;
    }
    return best;
  }

  /// Persian glues the possessive and the plural onto the noun itself —
  /// «پروفایلم», «تاریخچه‌ام», «فال‌هایم». A long enough prefix is still the
  /// same word; short words stay exact so nothing matches by accident.
  static bool _contains(Set<String> tokens, String word) {
    if (tokens.contains(word)) return true;
    if (word.length < 4) return false;
    for (final token in tokens) {
      if (token.length > word.length && token.startsWith(word)) return true;
    }
    return false;
  }
}
