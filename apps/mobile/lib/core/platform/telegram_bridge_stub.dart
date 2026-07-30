import '../config/android_bridges_switch.dart';
import 'android_platform_bridge.dart';
import 'telegram_platform_bridge.dart';

/// Non-web resolution (VM, tests, native targets).
///
/// The Play build (ENABLE_ANDROID_BRIDGES) gets [AndroidPlatformBridge] so
/// sharing and links work natively. Every other non-web target — including
/// `flutter analyze` and `flutter test` on the Dart VM, which never set the
/// define — keeps the safe no-op bridge, exactly as before.
TelegramPlatformBridge resolveTelegramBridge() => kAndroidBridgesEnabled
    ? const AndroidPlatformBridge()
    : const UnavailableTelegramBridge();
