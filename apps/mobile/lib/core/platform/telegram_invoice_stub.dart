/// Non-web resolution: Telegram invoices need the WebApp SDK, so outside a
/// web build the sheet can never open. Mirrors the bridge-stub philosophy —
/// a calm, explicit outcome instead of a crash.
Future<String> openTelegramInvoice(String url) async => 'unavailable';
