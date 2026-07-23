# Sprint 05 — Phase 1: Product Inventory

Baseline commit: `5e56a7fac10fd3891fab3a25635a0849f68e2ac9` (cleanup) · Stable tag: `sprint04-stable` → `be6e9b5`.
Method: actual code + test inspection (not filename inference). Backend (NestJS/Prisma) is genuinely functional and integration-tested; the mobile app has real feature logic but the **Telegram Mini App delivery layer and AI reading generation are not production-ready**, which are the two decisive v1.0 gaps.

Status legend: **COMPLETE** · **PARTIAL** · **MOCK** (interface/no-op or canned data) · **NOT IMPLEMENTED** · **BLOCKED**.

## Module inventory

### 1. Authentication — COMPLETE (backend) / PARTIAL (mobile)
- Files: `apps/api/src/modules/auth/{auth.service,auth.controller,telegram-init-data,token.service}.ts`; `apps/mobile/lib/features/auth/application/auth_controller.dart`; tests `auth.e2e-spec.ts`, `telegram-init-data.spec.ts`, `auth_controller_test.dart`.
- Backend: `POST /api/v1/auth/telegram` (only public auth route); global `AuthGuard` protects the rest.
- Missing: mobile can only obtain `initData` via the `DEV_TELEGRAM_INITDATA` dart-define seam because the real Telegram bridge is a no-op (item 15).
- Criticality: **P0** · v1.0: **yes**.
- Evidence: `telegram-init-data.ts` rebuilds the data-check-string and `timingSafeEqual`s the HMAC-SHA256; e2e logs in a fresh user and asserts the 401 contract.

### 2. Onboarding — NOT IMPLEMENTED
- Files: only splash (`splash_page.dart`, `startup_controller.dart`); `storage_keys.dart` declares `onboardingComplete` but it is never read/written.
- Backend: none. Missing: no onboarding UI/route at all.
- Criticality: **P2** · v1.0: **no**.
- Evidence: grep `onboardingComplete` → only the constant declaration.

### 3. Home / Landing — COMPLETE
- Files: `route_guards.dart` (redirects ready startup `/splash` → `/explore`), `explore_page.dart`.
- Backend: none (registry-driven). Missing: nothing for scope.
- Criticality: **P0** · v1.0: **yes**.

### 4. Fortune catalog (Explore) — COMPLETE (one catalog mismatch)
- Files: `fortune_registry.dart` (5 fortunes), `explore_page.dart`, `fortune_grid_card.dart`; backend `fortune-catalog.ts` (4 fortunes).
- Backend: none for listing; reading creation validates against `FORTUNE_CATALOG`.
- Missing: mobile registry has `coffee` (photo, `availability: soon`) not present in backend catalog; unavailable cards show a "coming soon" snackbar.
- Criticality: **P0** · v1.0: **yes**.
- Evidence: mobile = hafez/tarot/dream/love/coffee(soon); backend = hafez/tarot/dream/love.

### 5. Individual fortune flows / input kinds — PARTIAL
- intention, longText (dream), twoNames (love) = COMPLETE; photo (coffee) = NOT IMPLEMENTED.
- Files: `ritual_entry_page.dart`, `ritual_entry_controller.dart`, `fal_input.dart`; backend `readings.service.ts` `assertOfferingComplete`.
- Backend: `POST /api/v1/readings` (validates per `inputKind`).
- Missing: `FortuneInputKind.photo` returns an empty widget / `OfferingNeedsMore`, guarded as `soon`; no image capture/upload.
- Criticality: **P1** · v1.0: **no** (3 input kinds ship; photo can wait).
- Evidence: `fal_input.dart` photo branch — "Photo offerings arrive in a later sprint."

### 6. Reading / result page — COMPLETE
- Files: `reading_page.dart` (handed-in entity + cold deep-link fetch-by-id), `reading_submission_controller.dart` (in-flight guard + persistent Idempotency-Key across retryable failures); backend `readings.service.ts`.
- Backend: `POST /api/v1/readings`, `GET /api/v1/readings/:id`.
- Missing: "Save" is a snackbar-only confirmation (already persisted); "Share" is an explicit "coming soon".
- Criticality: **P0** · v1.0: **yes**.

### 7. History — COMPLETE
- Files: `history_page.dart`, `history_controller.dart` (cursor pagination, load-more, empty/error), backend `readings.repository.ts` `list()`.
- Backend: `GET /api/v1/readings` (opaque cursor, user-scoped, newest-first).
- Criticality: **P1** · v1.0: **yes**.
- Evidence: `take: limit + 1`, `cursor/skip`, `orderBy [createdAt desc, id desc]`.

### 8. Favorites — NOT IMPLEMENTED
- Files: none. Backend: none (no model, no endpoint). Missing: entirely absent.
- Criticality: **P2** · v1.0: **no**.
- Evidence: repo-wide grep favorite/favourite/bookmark → zero matches.

### 9. Wallet / coins — COMPLETE
- Files: `wallet.service.ts` (atomic conditional debit, compensating refund, starter credit as a real ledger row, unique-constraint duplicate-charge defense), `wallet.repository.ts`, `wallet_page.dart`, `wallet_controller.dart`; tests `wallet.service.spec.ts`, `wallet.e2e-spec.ts`, `wallet_test.dart`.
- Backend: `GET /api/v1/wallet` (read-only; balance mutates server-side only during reading debit/refund).
- Missing: no top-up/purchase route; "Daily reward" card is an honest "coming soon".
- Criticality: **P0** · v1.0: **yes**.
- Evidence: `decrementIfAffordable` = `updateMany where balance >= cost`.

### 10. Subscription / VIP (entitlements) — PARTIAL
- Files: `entitlements.service.ts` (`assessReading`, `grantSubscription`), `entitlements.controller.ts`, mobile `wallet_controller.dart` + `entitlement_dto.dart`; tests `entitlements.service.spec.ts`, `entitlements.e2e-spec.ts`.
- Backend: `GET /api/v1/entitlements/me`.
- Missing: **no purchase/checkout endpoint** — `grantSubscription` is admin/system-only with no route; mobile can display coverage/cost but cannot buy.
- Criticality: **P1** · v1.0: **no** (readings work via coins without it).
- Evidence: `entitlements.service.ts` — "There is intentionally no public purchase endpoint in Sprint 04."

### 11. Advertising readiness — NOT IMPLEMENTED
- Files: none. Missing: no ad SDK/hooks/placeholders.
- Criticality: **P2** · v1.0: **no**.
- Evidence: grep admob/advertis/rewarded/interstitial → zero matches.

### 12. Profile — MOCK / PLACEHOLDER
- Files: `profile_placeholder_page.dart` → `PlaceholderView` ("NOT the final feature UI").
- Backend: user data exists via `UsersService` but no profile endpoint is consumed.
- Missing: real profile UI; sign-out entry point (logic `auth_controller.signOut()` exists but no screen calls it).
- Criticality: **P2** · v1.0: **no**.

### 13. Settings — NOT IMPLEMENTED
- Files: none (theme/locale controllers exist but no settings UI/route). Prisma `SystemSetting` model declared but never queried.
- Missing: no settings screen/route, no locale/theme switcher surface.
- Criticality: **P2** · v1.0: **no**.
- Evidence: no `/settings` route in `app_routes.dart`.

### 14. Localization / RTL — COMPLETE
- Files: `l10n/app_en.arb` + `app_fa.arb` (45 keys each, at parity), generated `app_localizations_*.dart`, `supported_locales.dart`, `app.dart` (locale drives direction), Persian-digit extensions; tests `rtl_test.dart`, `locale_resolution_test.dart`.
- Backend: locale interceptor + Persian domain messages.
- Criticality: **P0** · v1.0: **yes**.

### 15. Telegram Mini App integration — MOCK / NOT IMPLEMENTED (interface only) — **BLOCKER**
- Files: `telegram_platform_bridge.dart` (interface + `UnavailableTelegramBridge`, all no-ops); `shared_providers.dart` always returns `const UnavailableTelegramBridge()`.
- Backend: initData verification is ready server-side, but the client never produces real initData.
- Missing: **no concrete web bridge** (`window.Telegram.WebApp` JS interop for `initData`/`expandViewport`/`hapticImpact`/`close`/`openLink`) AND **no `web/` build target** in `apps/mobile` (only `lib/`, `test/`, `pubspec.yaml`, `l10n.yaml`) — so there is no buildable Mini App and no `index.html` loading `telegram-web-app.js`.
- Criticality: **P0** · v1.0: **yes** — this is the delivery platform.
- Evidence: `shared_providers.dart` comment "the web bridge lands with auth" while returning the no-op; `apps/mobile` has no platform runner folders.

### 16. Backend APIs — COMPLETE (real, integration-tested)
- Files: all `apps/api/src/modules/*` controllers; e2e specs boot the real app against Postgres+Redis via supertest.
- Missing: no wallet top-up / subscription purchase writes (by design).
- Criticality: **P0** · v1.0: **yes**.

### 17. Database persistence — COMPLETE (one unused model)
- Declared (9): User, SystemSetting, FeatureFlag, IdempotencyKey, OutboxEvent, Reading, Wallet, CoinTransaction, Subscription.
- Queried: User, Subscription, Reading, Wallet, CoinTransaction, IdempotencyKey, FeatureFlag, OutboxEvent.
- **Not queried: `SystemSetting`** (declared only).
- Criticality: **P1** · v1.0: **yes**.

### 18. Error / loading / empty states — COMPLETE
- Files: `design_system/components/{fortune_error_state,fortune_loading,fortune_empty_state}.dart`, `error_mapper.dart`, `failure_message_resolver.dart`; used in splash/history/wallet/reading/ritual; tests `error_state_test.dart`, `error_mapper_test.dart`.
- Backend: consistent error envelope (`error.code`) verified in e2e.
- Criticality: **P0** · v1.0: **yes**.

### 19. Analytics readiness — MOCK (no-op)
- Files: `analytics_service.dart` (+ `NoopAnalyticsService`), `analytics_event.dart`, `route_observer.dart`, `crash_reporting_service.dart` (`NoopCrashReportingService`), `feature_flags.dart` (both flags false).
- Missing: no vendor implementation; provider always returns `NoopAnalyticsService`.
- Criticality: **P2** · v1.0: **no** (hooks present, wiring deferred).

## Real API endpoints (prefix `api/v1`)
| Method | Path | Auth | Real |
|---|---|---|---|
| POST | `/auth/telegram` | public | yes |
| GET | `/entitlements/me` | bearer | yes |
| GET | `/health/live` | public | yes |
| GET | `/health/ready` | public | yes (Prisma + Redis) |
| POST | `/readings` | bearer | yes |
| GET | `/readings` | bearer | yes (cursor pagination) |
| GET | `/readings/:id` | bearer | yes (owner-scoped) |
| GET | `/system/info` | public | yes |
| GET | `/wallet` | bearer | yes |

No POST/PATCH/DELETE beyond `auth/telegram` and `readings`. Wallet and entitlements are read-only — no purchase/top-up route.

## Explicit placeholders / mocks / "coming soon"
- **`MockReadingProvider` is the active reading generator by default** — `readings.module.ts` selects it when `LLM_BASE_URL`/`LLM_API_KEY` are unset, and the real `AiReadingProvider` falls back to the mock on any error. Out-of-the-box readings are canned Persian copy.
- `UnavailableTelegramBridge` — no-op bridge always used.
- `NoopAnalyticsService`, `NoopCrashReportingService` — no-op observability.
- `ProfilePlaceholderPage` / `PlaceholderView`.
- "Coming soon": coffee fortune, wallet Daily reward, reading Share.
- Declared-but-unused: `onboardingComplete` key, `SystemSetting` model.

## P0 release blockers (must fix for v1.0)
1. **Telegram Mini App delivery** — add a Flutter `web/` target with `index.html` loading `telegram-web-app.js`, and a concrete `TelegramWebBridge` (JS interop) that supplies real `initData` and implements viewport/haptics/close/openLink. Without this the app cannot run inside Telegram and auth cannot obtain real initData. (Item 15)
2. **Reading generation** — decide the v1.0 product: ship the real `AiReadingProvider` wired to a provider/keys, or explicitly accept `MockReadingProvider` as the shipped experience. Currently defaults to canned copy. (Placeholders)

Everything else required for the core coin-based paid-reading loop (auth, catalog, ritual input for 3 kinds, reading, history, wallet ledger, entitlement assessment, localization/RTL, error/loading/empty states, backend APIs, persistence) is implemented and integration-tested.

## P1 items (v1.0-desirable / near-term)
- Subscription **purchase** endpoint + mobile checkout (entitlements today are assess-only). (Item 10)
- Catalog consistency: reconcile mobile `coffee` vs backend catalog, or hide `coffee` until backend supports it. (Item 4)
- Reading **Share** implementation (currently "coming soon"). (Item 6)
- Remove or use the unused `SystemSetting` model. (Item 17)

## P2 items (later)
Onboarding, Favorites, Settings screen, Profile real UI + sign-out entry, Advertising SDK, Analytics/crash vendor wiring, photo/coffee fortune, wallet Daily reward / top-up.

## Recommended Sprint 05 scope (exact)
Focus Sprint 05 on making the existing, tested core **actually shippable inside Telegram**, not on new features:
1. **P0 — Telegram web target + real bridge** (Flutter `web/`, `index.html` + `telegram-web-app.js`, `TelegramWebBridge` JS interop). Acceptance: app boots in Telegram, real `initData` reaches `POST /auth/telegram`, session established.
2. **P0 — Reading provider decision** — wire real `AiReadingProvider` (config + keys + prompt) OR ratify the mock as v1.0; document the choice.
3. **P1 — Catalog reconciliation** (coffee) and **Share** — small, closes visible "coming soon" gaps.
4. Defer all P2 (onboarding, favorites, settings, profile UI, ads, analytics vendor, photo fortune) to post-v1.0.

Do NOT begin feature implementation, add advertising SDKs, or redesign the UI in this phase.
