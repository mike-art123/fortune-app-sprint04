import 'telegram_platform_bridge.dart';
// The web implementation is swapped in only when `dart:js_interop` exists
// (i.e. a web build). Every other target — including the Dart VM that runs
// `flutter test` and `flutter analyze` — resolves to the no-op stub.
import 'telegram_bridge_stub.dart'
    if (dart.library.js_interop) 'telegram_web_bridge.dart';

/// The platform-appropriate Telegram bridge: the real WebApp bridge inside a
/// Telegram Mini App, a safe no-op everywhere else.
TelegramPlatformBridge createTelegramBridge() => resolveTelegramBridge();
