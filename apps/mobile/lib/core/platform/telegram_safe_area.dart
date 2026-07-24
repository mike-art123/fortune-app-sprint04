import 'telegram_safe_area_base.dart';
// The web reader (dart:js_interop) is swapped in only on a web build; every
// other target — including the VM that runs flutter test/analyze — uses the
// no-op stub. Mirrors telegram_bridge_factory.dart.
import 'telegram_safe_area_stub.dart'
    if (dart.library.js_interop) 'telegram_safe_area_web.dart';

/// The platform-appropriate controller: real on web, no-op elsewhere.
TelegramSafeArea createTelegramSafeArea() => resolveTelegramSafeArea();

TelegramSafeArea? _instance;

/// Process-wide singleton; begins listening to Telegram on first access.
TelegramSafeArea get telegramSafeArea {
  return _instance ??= (createTelegramSafeArea()..start());
}
