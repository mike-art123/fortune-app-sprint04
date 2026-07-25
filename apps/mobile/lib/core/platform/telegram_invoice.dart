// Telegram Stars invoice sheet. The web implementation is swapped in only when
// `dart:js_interop` exists (a web build); `flutter test`/`analyze` and native
// targets resolve to the stub, exactly like the Telegram bridge factory.
export 'telegram_invoice_stub.dart'
    if (dart.library.js_interop) 'telegram_invoice_web.dart';
