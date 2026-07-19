# Foundation Phase 1 — Notes, Reference Status & Deviations

## Reference status
- The prior **React Telegram Mini App** build (Home, Result, Share, Explore, and all 5 Ritual
  Entry families on the Illuminated Sky palette) is retained as **design & UX reference**.
  Per the Director's decision, the production frontend is now **Flutter** (docs 35, 42, 48, 50).
  Entry visuals/microcopy/motion from the React build should be ported into Flutter feature phases.

## Deviation: existing tested backend
- A tested NestJS backend already exists in the previous repo (`backend/api`, 131 passing tests)
  with modules `fal`, `coins`, `ads`. Docs 43/47 name modules `readings/fortunes`, `wallet`,
  `rewardedAds`. This Phase-1 foundation scaffolds the doc-aligned structure with placeholder
  modules. **Recommendation:** migrate the existing tested logic into the new module names
  (fal→readings/fortunes, coins→wallet, ads→rewardedAds) rather than rewrite — a dedicated
  Backend Migration task, not part of Phase 1.

## Not runnable in the authoring environment
- This scaffold was authored offline; `flutter`, `nest`, `prisma`, lint and tests were **not**
  executed here. Acceptance criteria 1–9 must be validated on a machine with the toolchains.

---

# Document 51 — Flutter Foundation (execution notes)

## Phase A inspection result
The Phase-1 Flutter skeleton was **restructured, not discarded**. Preserved:
Illuminated Sky palette values, Riverpod/GoRouter/Dio choice, ApiClient
abstraction, RTL-first Persian default, monorepo layout, backend untouched.

Expanded to meet doc 51:
- single `main.dart` → four flavor entry points + shared `bootstrap()`
- flat tokens → `design_system/foundations/*` + semantic `FortuneColors` ThemeExtension
- `Failure`/`Result` → `AppFailure` (12 kinds, retryability, reauth) + sealed `Result`
- added interceptors (request-id, locale, metadata, auth, safe retry)
- added logging w/ redaction, analytics, crash reporting, feature flags,
  connectivity, lifecycle, Telegram bridge, storage migrations
- added DS components, motion primitives, a11y primitives
- added splash + startup controller, wallet + profile placeholders
- hardcoded Persian strings → localization layer with ARB-mirrored keys

## Deliberate deviations (doc 51 §6 requires these be stated)
1. **`AppStrings` instead of generated `AppLocalizations`.** `flutter gen-l10n`
   could not be executed here, and referencing a non-existent generated class
   would break compilation. Keys mirror the ARB files exactly; swapping is a
   one-file change because call sites use `context.strings`.
2. **SDK constraint set to `>=3.6.0`.** Required by `Color.withValues`. Doc 51 §6
   says the constraint MUST match the installed toolchain — verify locally.
3. **`cardTheme` omitted** from ThemeData: `CardTheme` vs `CardThemeData` differs
   across Flutter versions; `FortuneCard` owns card styling anyway.
4. **No golden tests** — doc 51 §36.4 defers them until typography/assets settle.
5. **Native shells not generated** — `flutter create .` is a local step.

## Not executed here
`flutter pub get`, `gen-l10n`, `build_runner`, `dart format`, `flutter analyze`,
`flutter test` were **not run** (no toolchain/network in the authoring
environment). No pass/fail claims are made about them.

---

# Document 52 — NestJS Foundation (execution notes)

## Phase A inspection result
Phase-1 API skeleton restructured, not discarded. Preserved and upgraded:
zod env validation (now full §9 schema with production safety refinement),
request-id (now middleware with hostile-value rejection), response envelope
(now with meta.requestId), health (now split live/ready with indicators),
Prisma/Redis services (now with transaction service, namespacing, JSON helpers).
Placeholder product modules (fortunes/readings/wallet) intentionally removed
from the module graph until their feature documents; auth/users remain as seams.

## Contract reconciliation (docs 33 vs 52)
Doc 33 defines `{success,data,...}` / `{success:false,error,requestId}`;
doc 52 §12/§35 shows `{data,meta}` / `{error:{...,requestId}}`. Implemented a
superset satisfying both: success `{success:true,data,meta:{requestId}}`,
error `{success:false,error:{code,message,details?,retryable?},requestId}`.

## Deliberate deviations
1. **`exactOptionalPropertyTypes` omitted** from tsconfig: it conflicts with
   Nest/class-validator DTO idioms; all other §7 strict flags are enabled.
2. **Rate limiting** uses @nestjs/throttler in-memory store; the Redis-backed
   store hook is documented and lands with feature-specific limits (§27 allows).
3. **BullMQ**: queue names/options/versioned-payload contract defined; no
   queues registered because no workers exist yet (§22 permits placeholders).
4. **DenyAllTokenVerifier**: every non-@Public route 401s until Document 53 —
   deliberately NOT an insecure mock-accept (§55).
5. **lockfile**: `package-lock.json` cannot be generated offline; run
   `npm install` locally to produce it (§52 deliverable noted as pending).

## Not executed here
`npm ci`, `prisma generate/migrate`, lint, format, unit/e2e tests, build,
docker — none were run (no toolchain/network). No pass/fail claims are made.
Migration baseline must be created locally with `npm run db:migrate`.

---

# Sprint 01 — Vertical Slice (execution notes)

Scope delivered: Launch → Splash → Explore (registry-driven 2-col grid) →
Ritual Entry (whisper offering, gentle validation) → Reading placeholder
(honest acknowledgment, no fake content). Fortune Registry is the single
source of truth; UI contains zero per-fortune logic (verified by grep).

Spec basis: docs 68/69/70 arrived as empty skeletons, so the slice implements
the approved React Entry designs (Whisper pattern, microcopy, per-family pace)
+ Constitution/UX Bible rules, ported into Flutter.

Coffee is registry-marked `soon` (photo offering lands with the media sprint);
Explore shows it honestly with a coming-soon label.

NOT executed here (no toolchain): flutter pub get / dart format / flutter
analyze / flutter test / flutter build web. Imports verified programmatically.

---

# Sprint 02 — Backend-Integrated Vertical Slice (execution notes)

Delivered: Ritual Entry → POST /api/v1/readings → ReadingsService →
MockReadingProvider (seam for doc-56 AI) → Prisma persist → envelope →
Flutter ReadingRepository → sealed submission states → real Reading screen.

Decisions:
- POST /readings is temporarily @Public: real Telegram auth is Document 53's
  scope and the foundation verifier denies all tokens. Reading.userId is
  nullable until then (documented in the controller).
- Server-side FORTUNE_CATALOG is the authoritative validator; the mobile
  registry mirrors it for UI. Coffee is absent server-side until media lands.
- Mock provider returns calm reflective Persian copy per input kind — never
  prophecy claims; replaced later without contract changes.
- Default mobile API base URL corrected to /api/v1.

Environment: flutter/dart absent; npm present but registry blocked (403 via
egress proxy) → install/build/test could not run. All imports (both apps,
src+test) verified programmatically. Migration for the Reading model must be
created locally: `npm run db:migrate`.

---

# Sprint 03 — handoff snapshot (session boundary)
Completed in this session: LLM env schema (BASE_URL/API_KEY/MODEL/TIMEOUT/RETRIES),
AiConfig (typed, isConfigured) registered in config.module, both .env.example files.
Everything else in Sprint 03 is pending — see وضعیت-کامل-پروژه-برای-چت-جدید.md §5
in outputs for the exact continuation plan.

# Sprint 04 — identity / entitlements / atomic debit (execution notes)

Scope came from doc 53's seams already present in the codebase (auth.module,
token-verifier.interface, wallet re-anchor comments) plus the handoff doc §5.3.

What landed:
- **Telegram auth**: `POST /auth/telegram` verifies real Mini App initData
  (HMAC-SHA256 keyed with "WebAppData", constant-time compare, max-age with
  bounded clock skew) and upserts the `tg:<id>` user anchor. Raw initData and
  user names are never logged.
- **JWT lifecycle**: `TokenService` signs/verifies compact JWTs with
  node:crypto only — EdDSA (ed25519) or RS256 keys from env; ephemeral ed25519
  outside production (warned at boot); production refuses to boot without a
  persistent keypair and bot token (env schema). No HS256, no `alg: none`.
- **Principal everywhere**: `@Public` removed from readings and wallet;
  `x-anon-id` is gone (wallets re-anchored to `userId`; `anonId` column stays
  as a migration breadcrumb). `DenyAllTokenVerifier` is a test seam only.
- **Entitlements**: active subscription ⇒ reading covered; otherwise
  backend-authoritative `WALLET_READING_COST`. Subscriptions have no purchase
  endpoint yet — payments arrive with their own document; grants are
  system-level (`EntitlementsService.grantSubscription`).
- **Atomic debit + refund**: conditional decrement (`balance >= cost`) and the
  signed ledger row commit in one transaction; INSUFFICIENT_COINS rolls back
  everything. Failure after a debit refunds via a compensating row that is
  UNIQUE per debit — double refunds are structurally impossible, as are double
  charges for one Idempotency-Key (unique `(walletId, kind, refId)` backstop
  beneath the durable HTTP idempotency layer).
- **Migration**: `prisma/migrations/20260719000000_init_identity_entitlements`
  is the first real migration (none existed). It was hand-written offline; on
  a networked machine verify no drift with
  `npx prisma migrate diff --from-migrations prisma/migrations --to-schema-datamodel prisma/schema.prisma --shadow-database-url "$DATABASE_URL"`.
- **Validation**: `npm run validate:sprint04` (scripts/validate-sprint-04.sh)
  = npm ci → prisma generate → format → lint → unit → build → migrate deploy →
  e2e. `--with-mobile` optionally appends the Sprint 03 §2 Flutter check;
  Flutter itself is not in Sprint 04 scope.

Known follow-ups:
- `package-lock.json` must be generated on a networked machine
  (`npm install --package-lock-only`) — the validation script refuses to run
  without it, because `npm ci` (and CI) need it.
- Mobile half landed in the same sprint: session bootstrap at startup
  (stored-token reuse → Telegram initData login → calm Unauthenticated),
  bearer-token identity on every request, `x-anon-id` removed (v2 storage
  migration deletes the stored anon id), Idempotency-Key on reading
  submissions with a charge-safe retry cycle, and wallet/entitlement surfaces
  reading the backend's word (`GET /entitlements/me`). The development seam is
  `DEV_TELEGRAM_INITDATA` (dev flavor only; still fully backend-verified).
- Legacy anon wallets/readings (null userId) are invisible to authenticated
  users; a data migration adopting them into `tg:<id>` users is a doc 53
  decision, not taken unilaterally.
