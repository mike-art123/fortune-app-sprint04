/// Abstraction over the Telegram Mini App environment (doc 51 §32).
/// The app MUST degrade gracefully outside Telegram, and the raw payload is
/// NEVER trusted — the backend verifies `initData` before any session exists.
abstract interface class TelegramPlatformBridge {
  bool get isAvailable;

  /// Raw init payload. Treated as opaque, sent to the backend for verification.
  String? get initData;

  Future<void> expandViewport();
  Future<void> hapticImpact();
  Future<void> close();
  Future<void> openLink(String url);

  /// Open a t.me link inside Telegram (e.g. the share dialog); unlike
  /// [openLink] this handles t.me schemes and keeps the Mini App open.
  Future<void> openTelegramLink(String url);

  /// Show / hide the Telegram Mini App native back button. No-op off Telegram.
  Future<void> showBackButton();
  Future<void> hideBackButton();

  /// Register the SINGLE handler invoked when the native back button is tapped
  /// (null clears it). Only one underlying listener is ever registered, so
  /// repeated route changes never stack duplicate handlers.
  void setBackButtonHandler(void Function()? handler);
}

/// Used on every non-Telegram target. All calls are safe no-ops.
class UnavailableTelegramBridge implements TelegramPlatformBridge {
  const UnavailableTelegramBridge();

  @override
  bool get isAvailable => false;
  @override
  String? get initData => null;
  @override
  Future<void> expandViewport() async {}
  @override
  Future<void> hapticImpact() async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> openLink(String url) async {}
  @override
  Future<void> openTelegramLink(String url) async {}
  @override
  Future<void> showBackButton() async {}
  @override
  Future<void> hideBackButton() async {}
  @override
  void setBackButtonHandler(void Function()? handler) {}
}
