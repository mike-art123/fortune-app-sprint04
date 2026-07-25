import 'dart:async';
import 'dart:js_interop';

/// `window.Telegram.WebApp`, read defensively (absent outside Telegram).
@JS('Telegram.WebApp')
external _WebApp? get _telegramWebApp;

extension type _WebApp(JSObject _) implements JSObject {
  external void openInvoice(String url, JSFunction callback);
}

/// Opens Telegram's native Stars payment sheet and resolves with the status
/// Telegram reports: `paid`, `cancelled`, `failed` or `pending`. Resolves
/// `unavailable` when the WebApp SDK is not present (outside Telegram).
Future<String> openTelegramInvoice(String url) {
  _WebApp? app;
  try {
    app = _telegramWebApp;
  } catch (_) {
    app = null;
  }
  if (app == null) return Future.value('unavailable');

  final completer = Completer<String>();
  void onStatus(String status) {
    if (!completer.isCompleted) completer.complete(status);
  }

  try {
    app.openInvoice(url, onStatus.toJS);
  } catch (_) {
    return Future.value('unavailable');
  }
  return completer.future;
}
