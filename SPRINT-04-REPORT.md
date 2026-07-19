# SPRINT-04-REPORT — identity / entitlements / atomic debit (backend + Flutter)

Status: **The Sprint 04 implementation is feature-complete (backend and
Flutter, both consistent with the Sprint 04 authentication architecture).
Production verification remains pending until the complete validation pipeline
has been executed successfully in a fully provisioned environment.** See
`SPRINT-04-VALIDATION-EVIDENCE.md` for exactly what has and has not run.

## 1. Scope delivered

### Backend (apps/api)
- **Telegram initData verification** (`telegram-init-data.ts`): HMAC-SHA256
  keyed with `WebAppData`, timing-safe comparison, max-age with bounded clock
  skew, strict user extraction. Pure function; raw initData never logged.
- **JWT lifecycle** (`token.service.ts`): node:crypto only. EdDSA (ed25519) or
  RS256 from PEM env keys; ephemeral ed25519 outside production (loudly
  warned); production refuses to boot without bot token + persistent keypair
  (env schema). No HS256, no `alg: none`, iss/aud/exp/iat enforced.
- **Login** `POST /auth/telegram` → verified identity → upserted `tg:<id>`
  user anchor → Bearer access token. `TelegramTokenVerifier` now backs the
  doc 52 §28 guard seam; `DenyAllTokenVerifier` survives only as a test seam.
- **Principal everywhere**: `@Public` removed from readings and wallet;
  `x-anon-id` deleted; wallets anchored to `userId` (anonId column kept as a
  migration breadcrumb); history list/detail enforce ownership.
- **Entitlements**: active subscription covers readings; otherwise the
  backend-authoritative `WALLET_READING_COST`. Exposed read-only at
  `GET /entitlements/me`. Subscription grants are system-level
  (`grantSubscription`) — deliberately no purchase endpoint (payments are a
  separate document; requirement #4).
- **Atomic debit + refund**: one transaction = conditional decrement
  (`balance >= cost`) + signed ledger row. INSUFFICIENT_COINS (402) rolls back
  everything. Post-debit failure triggers an idempotent compensating refund.
  Duplicate-charge/refund guards are layered: durable HTTP idempotency
  (Idempotency-Key) above a DB UNIQUE `(walletId, kind, refId)` backstop.
- **Migration**: first real migration
  (`20260719000000_init_identity_entitlements`) + lock file; drift is checked
  against a real Postgres shadow DB by the validation script.

### Flutter (apps/mobile)
- **Session bootstrap** (`features/auth/`): at startup — stored token reused
  if fresh (claims peeked client-side for expiry only; verification stays
  server-side), else Telegram initData login, else calm `Unauthenticated`
  (outsideTelegram / rejected / network). A backend 401 mid-session emits on
  `SessionEvents`; the controller drops the token and re-establishes once.
- **Identity on the wire**: the existing `AuthInterceptor` now actually has a
  token to attach; `x-anon-id` is fully removed (header constant, provider,
  wallet usage) and the v2 storage migration deletes the stored anon id.
- **Dev/test seam**: `DEV_TELEGRAM_INITDATA` dart-define, honored only in the
  development flavor, still fully verified by the backend. Tests override the
  bridge/repository providers — nothing bypasses verification.
- **Paid-reading flow**: every submission carries an `Idempotency-Key`
  (uuid v4) with a charge-safe cycle — retryable failures reuse the key (one
  charge slot), success/definitive refusal starts a fresh cycle.
  `INSUFFICIENT_COINS` (and 402) map to a dedicated failure kind with calm
  Persian copy.
- **Wallet & subscription status**: the wallet page shows the backend's word —
  balance, ledger (incl. new debit/refund kinds), and the entitlement line
  ("subscription active" or the per-reading coin price) from
  `GET /entitlements/me`. The entitlement lookup failing never blocks the
  wallet; the client never invents a price.
- **Error contract compatibility**: mapper now speaks the real backend codes
  (`VALIDATION_FAILED`, `INSUFFICIENT_COINS`, `SUBSCRIPTION_REQUIRED`,
  `READING_FAILED`, `CONFLICT`, `REQUEST_TIMEOUT`) — fixing a pre-existing
  mismatch (`INVALID_INPUT`) inside Sprint 04's API-compatibility scope.

## 2. Explicitly out of scope (per instructions)
- Payment-provider purchasing (requirement #4) — no purchase endpoint, no
  fake buy buttons.
- Sprint 05 hardening; unrelated redesigns.
- Adoption/merge of legacy anonymous wallets into `tg:<id>` users — a product
  decision for doc 53, flagged in PHASE1_NOTES, not taken unilaterally.

## 3. Tests
- Backend: ~45 unit specs across initData (13), token service (10), auth
  service (5), entitlements (5), wallet debit/refund (13+), readings
  orchestration (19 incl. refund-on-failure, replay, insufficient-funds);
  e2e specs for auth, wallet economy (incl. 5-way same-key race and
  run-the-wallet-dry), readings isolation, entitlements price-matches-debit.
- Flutter: auth controller (10 scenarios incl. 401 recovery, dev seam,
  expired-token re-login), idempotency-cycle tests, wallet + entitlement
  tests, error-contract tests; existing suites updated to the new signatures.

## 4. How to validate
```bash
npm run validate:sprint04          # full gates, fail-fast, honest summary
```
Prereqs on the machine: Node ≥20 with npm registry access, Docker (Postgres +
Redis), Flutter SDK. First run only: `npm install --package-lock-only` to
create the lockfile the script (and `npm ci`, and CI) require.

## 5. Risks / notes for the first networked run
- The migration SQL was written offline; the script's drift gate
  (`prisma migrate diff --exit-code` against a real shadow DB) is the
  authoritative check. If it reports drift, regenerate with
  `prisma migrate diff --from-empty --to-schema-datamodel` and compare.
- `dart format` has never actually run over this repo (pre-existing: the tree
  contains 100+-column lines from before this sprint; `page_width: 100` is now
  configured to match the codebase style). If the format gate still reports
  diffs, run `dart format .` once and commit the mechanical result.
- Similarly `npm run api:format:check`/`lint` are expected to pass but have
  not executed here; treat any finding as a mechanical fixup, not a design
  change.
