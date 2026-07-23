# Sprint 05 — Phase 2 (P0) delivery notes

Two P0 blockers from the product inventory, closed without new features, UI
redesign, or schema changes.

## 1. Telegram Mini App integration

The app now ships as a **web build** and talks to the real Telegram WebApp SDK.

- `apps/mobile/web/index.html` loads `https://telegram.org/js/telegram-web-app.js`
  before Flutter, so `window.Telegram.WebApp` is present at startup. Viewport is
  locked (no zoom) per Mini App guidance.
- `TelegramWebBridge` (`lib/core/platform/telegram_web_bridge.dart`) is a thin,
  defensive `dart:js_interop` wrapper over `window.Telegram.WebApp` — `initData`,
  `expand`, `HapticFeedback.impactOccurred`, `close`, `openLink`, `ready`.
- It is swapped in **only on web** through a conditional import
  (`telegram_bridge_factory.dart` → `telegram_bridge_stub.dart`
  `if (dart.library.js_interop) telegram_web_bridge.dart`). The Dart VM used by
  `flutter analyze` / `flutter test` always resolves to the no-op stub, so tests
  are unchanged.
- `telegramBridgeProvider` now returns `createTelegramBridge()` instead of the
  hard-coded no-op.

**Auth path (already correct, now fed by real data):** `AuthController._initData()`
reads `bridge.initData` first and authenticates **only** through
`POST /api/v1/auth/telegram`. `DEV_TELEGRAM_INITDATA` is honoured **only in the
development flavor** (`EnvironmentLoader` sets it to `null` otherwise), so there
is no production dependence on it — production gets its `initData` exclusively
from the WebApp bridge.

**CI validation:** `ci.yml` mobile job now runs `flutter build web --release`,
which compiles the js_interop bridge and the `web/` target (the analyze/test
gates run on the VM and never exercise web-only code).

**Verification that requires a human (cannot be automated here):** deploy the
`build/web` output to HTTPS, register it as a Mini App via BotFather, open it in
Telegram, and confirm a real `initData` produces an authenticated session. CI
green proves the web target compiles; it does not prove the live Telegram
handshake.

## 2. AI reading engine

The real provider already existed (`AiReadingProvider`) with timeout, retry,
response validation, and graceful fallback. Sprint 05 makes it the **enforced**
production generator:

- `env.schema.ts` now **refuses to boot in production** without `LLM_BASE_URL`
  and `LLM_API_KEY` (same fail-fast pattern as `TELEGRAM_BOT_TOKEN` / JWT keys).
  So the mock can never be the primary generator in production.
- Selection stays config-driven (`readings.module.ts`): AI when configured, mock
  otherwise. In `test`/`development` (no keys) the mock is used, which keeps the
  e2e suite runnable without a live LLM.
- `MockReadingProvider` remains **only** as `AiReadingProvider`'s internal
  graceful fallback (unreachable/slow/untrustworthy model → calm mock copy, never
  an error screen). It is never selected as the primary provider in production.
- Contract unchanged (`GeneratedReading { title, reading }`); all current fortune
  input kinds (intention, longText, twoNames) are supported by both providers.

**Operator action:** set `LLM_BASE_URL`, `LLM_API_KEY` (and optionally
`LLM_MODEL`, `LLM_TIMEOUT_MS`, `LLM_MAX_RETRIES`) in the production environment.
Keys live only on the server and are never shipped to the client.

## Not in scope (P1 — deferred)

Subscription purchase endpoint + checkout, catalog reconciliation (`coffee`),
reading Share, unused `SystemSetting` model, and all P2 items remain open.
