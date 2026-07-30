/// Guest (device-anchored) login for the Play build.
///
/// The Telegram Mini App proves identity with `initData`; the Android app has
/// no Telegram context, so it signs in as a guest with a stable, app-generated
/// device id instead (POST /auth/guest — dark behind the backend `auth.guest`
/// flag). Compile-time on purpose: web builds never carry the guest path, and
/// the Android build turns it on with
///   flutter build appbundle --dart-define=ENABLE_GUEST_AUTH=true
const bool kGuestAuthEnabled = bool.fromEnvironment('ENABLE_GUEST_AUTH');
