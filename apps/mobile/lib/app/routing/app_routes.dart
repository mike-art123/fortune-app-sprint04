/// Centralised route names and paths (doc 51 §12.1).
abstract final class AppRoutes {
  static const splashName = 'splash';
  static const splashPath = '/splash';

  static const exploreName = 'explore';
  static const explorePath = '/explore';

  static const ritualName = 'ritual';
  static const ritualPath = '/ritual/:fortuneId';

  static const readingName = 'reading';
  static const readingPath = '/reading/:readingId';

  static const walletName = 'wallet';
  static const walletPath = '/wallet';

  static const historyName = 'history';
  static const historyPath = '/history';

  static const profileName = 'profile';
  static const profilePath = '/profile';

  static String ritual(String fortuneId) => '/ritual/$fortuneId';
  static String reading(String readingId) => '/reading/$readingId';
}

/// Deep-link parameter validation. Malformed ids must never crash the app
/// or reach the backend (doc 51 §12.5, §33).
abstract final class RouteParams {
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static bool isValidId(String? value) =>
      value != null && _safeId.hasMatch(value);
}
