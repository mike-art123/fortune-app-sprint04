import 'app_routes.dart';
import 'fortune_destinations.dart';

/// The one-shot destination named by the URL that opened the app — the
/// `?start=` parameter carried by the buttons under notification messages
/// (`daily`, `history`).
///
/// Read once from `Uri.base`, spent on the first leave-splash redirect, and
/// never looked at again: a reload mid-session must not drag the reader back
/// to wherever the morning message pointed.
abstract final class StartIntent {
  static bool _spent = false;

  /// The route the opening URL asked for, or null. Reading it spends it.
  static String? consume() {
    if (_spent) return null;
    _spent = true;
    return targetFor(Uri.base.queryParameters['start']);
  }

  /// The pure mapping, kept separate from the one-shot state for tests.
  static String? targetFor(String? value) {
    switch (value) {
      case 'daily':
        return FortuneDestinations.pathFor('daily');
      case 'history':
        return AppRoutes.historyPath;
      default:
        return null;
    }
  }
}
