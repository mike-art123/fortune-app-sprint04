import 'dart:js_interop';

import 'telegram_platform_bridge.dart';

/// Web resolution: the real Telegram Mini App bridge (doc 51 §32).
///
/// Compiled ONLY for the web target, via the conditional import in
/// `telegram_bridge_factory.dart`. The VM/stub build never loads this file, so
/// `flutter test` and native targets keep using [UnavailableTelegramBridge].
TelegramPlatformBridge resolveTelegramBridge() => TelegramWebBridge();

/// `window.Telegram.WebApp`, or `null` when the SDK has not loaded (i.e. the
/// page is open outside Telegram). Reading it can throw if `Telegram` itself is
/// absent, so every access goes through [TelegramWebBridge._app].
@JS('Telegram.WebApp')
external _WebApp? get _telegramWebApp;

extension type _WebApp(JSObject _) implements JSObject {
  external String? get initData;
  external void ready();
  external void expand();
  external void close();
  external void openLink(String url);
  @JS('HapticFeedback')
  external _HapticFeedback? get hapticFeedback;
}

extension type _HapticFeedback(JSObject _) implements JSObject {
  external void impactOccurred(String style);
}

/// Thin, defensive wrapper over the Telegram WebApp global. The raw payload is
/// never trusted here — it is sent to the backend for verification. Outside
/// Telegram every method degrades to a no-op, exactly like the stub bridge.
class TelegramWebBridge implements TelegramPlatformBridge {
  TelegramWebBridge() {
    _app()?.ready();
  }

  /// The WebApp global, or `null` if it (or `Telegram`) is not present.
  _WebApp? _app() {
    try {
      return _telegramWebApp;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isAvailable {
    final data = initData;
    return data != null && data.isNotEmpty;
  }

  @override
  String? get initData => _app()?.initData;

  @override
  Future<void> expandViewport() async {
    _app()?.expand();
  }

  @override
  Future<void> hapticImpact() async {
    _app()?.hapticFeedback?.impactOccurred('light');
  }

  @override
  Future<void> close() async {
    _app()?.close();
  }

  @override
  Future<void> openLink(String url) async {
    _app()?.openLink(url);
  }
}
