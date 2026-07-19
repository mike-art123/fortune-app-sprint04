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
}
