import 'telegram_platform_bridge.dart';

/// Non-web resolution (VM, tests, native targets): a safe no-op bridge.
///
/// Selected by the conditional import in `telegram_bridge_factory.dart` on any
/// target that lacks `dart:js_interop`, so `flutter analyze` and `flutter test`
/// on the Dart VM never touch the web-only implementation.
TelegramPlatformBridge resolveTelegramBridge() =>
    const UnavailableTelegramBridge();
