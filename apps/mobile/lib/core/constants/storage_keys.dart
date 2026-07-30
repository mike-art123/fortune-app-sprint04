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

  /// Guest identity anchor for the Play build: a UUID minted once per install
  /// and exchanged at POST /auth/guest. An opaque anchor, not a secret.
  static const guestDeviceId = 'pref.guest_device_id';
  static const themeMode = 'pref.theme_mode';

  /// Ambient sound (scope §1). Device-level on purpose: whether a phone should
  /// make noise is a property of the phone, not of the account.
  static const audioEnabled = 'pref.audio_enabled';
  static const audioTheme = 'pref.audio_theme';
  static const audioVolume = 'pref.audio_volume';
  static const onboardingComplete = 'pref.onboarding_complete';

  /// The one-time disclaimer before the very first reading was acknowledged.
  static const disclaimerSeen = 'pref.disclaimer_seen';
  static const storageVersion = 'pref.storage_version';
}
