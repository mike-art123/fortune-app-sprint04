import 'telegram_safe_area_base.dart';

/// Non-web resolution (VM, tests, native): insets stay 0 and listening is a
/// no-op, so `flutter analyze` / `flutter test` never touch `dart:js_interop`.
TelegramSafeArea resolveTelegramSafeArea() => _StubTelegramSafeArea();

class _StubTelegramSafeArea extends TelegramSafeArea {
  @override
  void start() {}
}
