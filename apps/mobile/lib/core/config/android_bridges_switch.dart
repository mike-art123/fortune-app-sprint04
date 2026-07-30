/// Native Android stand-ins for the Telegram-only platform actions.
///
/// Inside the Mini App, sharing and links ride the Telegram WebApp bridge. The
/// Play build has no such bridge, so with this switch on it swaps in
/// `AndroidPlatformBridge`: the system share sheet for share links and
/// url_launcher for everything else. Compile-time on purpose — web builds and
/// tests never carry the plugin-backed path. The Android build turns it on
/// with
///   flutter build appbundle --dart-define=ENABLE_ANDROID_BRIDGES=true
const bool kAndroidBridgesEnabled = bool.fromEnvironment(
  'ENABLE_ANDROID_BRIDGES',
);
