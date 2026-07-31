/// Native Android stand-ins for the web-only platform actions.
///
/// Inside the Mini App, sharing, links and the cup photo ride the browser /
/// Telegram WebApp. The Play build has neither, so with this switch on it
/// swaps in the native paths: `AndroidPlatformBridge` (system share sheet +
/// url_launcher links) and the camera / photo-picker capture for the coffee
/// ritual. Compile-time on purpose — web builds and tests never carry the
/// plugin-backed path. The Android build turns it on with
///   flutter build appbundle --dart-define=ENABLE_ANDROID_BRIDGES=true
const bool kAndroidBridgesEnabled = bool.fromEnvironment(
  'ENABLE_ANDROID_BRIDGES',
);
