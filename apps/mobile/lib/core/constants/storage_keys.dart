/// Centralised storage keys. Secure keys hold credentials; preference keys
/// hold non-sensitive settings only (doc 51 §25).
abstract final class SecureKeys {
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
}

abstract final class PrefKeys {
  static const locale = 'pref.locale';

  /// LEGACY (pre-Sprint 04): the anonymous identity anchor. No longer read;
  /// kept only so the v2 storage migration can delete stored values.
  static const anonId = 'pref.anon_id';
  static const themeMode = 'pref.theme_mode';
  static const onboardingComplete = 'pref.onboarding_complete';
  static const storageVersion = 'pref.storage_version';
}
