# CHANGE-MANIFEST — Sprint 04 (identity / entitlements / atomic debit, backend + Flutter)

Baseline: `fortune-app-canonical.zip` (the canonical repo at the start of this session).
This list was produced by `diff -rq` between the baseline and the final tree — it is
mechanical, not hand-curated.

## Backend — apps/api

### Added
```
prisma/migrations/migration_lock.toml
prisma/migrations/20260719000000_init_identity_entitlements/migration.sql
src/config/auth.config.ts
src/common/decorators/idempotency-key.decorator.ts
src/modules/auth/telegram-init-data.ts            (+ telegram-init-data.spec.ts)
src/modules/auth/token.service.ts                 (+ token.service.spec.ts)
src/modules/auth/telegram-token.verifier.ts
src/modules/auth/auth.service.ts                  (+ auth.service.spec.ts)
src/modules/auth/auth.controller.ts
src/modules/auth/dto/telegram-login.dto.ts
src/modules/users/users.service.ts
src/modules/entitlements/entitlements.module.ts
src/modules/entitlements/entitlements.service.ts  (+ entitlements.service.spec.ts)
src/modules/entitlements/entitlements.controller.ts
test/auth.e2e-spec.ts
test/entitlements.e2e-spec.ts
test/support/telegram-auth.ts
```

### Modified
```
prisma/schema.prisma            CoinTransaction: +refType/+refId, UNIQUE(walletId,kind,refId); +Subscription; User relation
src/modules/auth/auth.module.ts             real verifier wired (TelegramTokenVerifier)
src/modules/auth/token-verifier.interface.ts DenyAll re-documented as test seam only
src/modules/users/users.module.ts           provides/exports UsersService
src/modules/wallet/wallet.service.ts        userId anchor; atomic debitForReading; idempotent refundDebit
src/modules/wallet/wallet.repository.ts     userId lookups; conditional decrement; ledger append; ref lookups
src/modules/wallet/wallet.controller.ts     principal instead of x-anon-id; @Public removed
src/modules/wallet/wallet.service.spec.ts   rewritten for the new economy
src/modules/readings/readings.service.ts    entitlement → debit → generate → persist → refund-on-failure; ownership on list/get
src/modules/readings/readings.controller.ts principal + Idempotency-Key; @Public removed
src/modules/readings/readings.repository.ts userId on create; user-scoped list
src/modules/readings/readings.module.ts     imports Entitlements + Wallet modules
src/modules/readings/readings.service.spec.ts rewritten for orchestration
src/config/env.schema.ts        +AUTH_TOKEN_TTL_SECONDS, +TELEGRAM_INITDATA_MAX_AGE_SECONDS, +WALLET_READING_COST; production requires bot token + JWT keypair
src/config/wallet.config.ts     +readingCostCoins
src/config/config.module.ts     +AuthConfig
src/app.module.ts               +EntitlementsModule
.env.example                    new auth/economy variables
test/app.e2e-spec.ts            real protected-route 401 assertion
test/readings.e2e-spec.ts       authenticated flow + cross-user isolation
test/wallet.e2e-spec.ts         authenticated flow + debit/idempotency/insufficient-coins/race
```

### Deleted
```
src/common/decorators/anon-id.decorator.ts
```

## Flutter — apps/mobile

### Added
```
lib/features/auth/domain/auth_session.dart
lib/features/auth/domain/auth_repository.dart
lib/features/auth/domain/access_token_claims.dart
lib/features/auth/data/auth_dto.dart
lib/features/auth/data/auth_repository_impl.dart
lib/features/auth/application/auth_controller.dart
lib/core/network/session_events.dart
lib/features/wallet/domain/entitlement_status.dart
lib/features/wallet/data/entitlement_dto.dart
test/features/auth_controller_test.dart
```

### Modified
```
lib/shared/providers/shared_providers.dart   anonIdProvider removed; sessionEvents wired to 401
lib/core/constants/header_keys.dart          x-anon-id header removed
lib/core/constants/storage_keys.dart         anon key marked legacy (kept for migration cleanup)
lib/core/constants/app_constants.dart        storageVersion 1 → 2
lib/core/persistence/storage_migrations.dart v2: deletes the stored anon id
lib/core/persistence/secure_storage.dart     TokenStore.saveAccessToken (single-token backend)
lib/core/config/app_config.dart              +devTelegramInitData (dev-only seam)
lib/core/config/environment_loader.dart      DEV_TELEGRAM_INITDATA define (dev flavor only)
lib/core/errors/app_failure.dart             +insufficientCoins, +subscriptionRequired
lib/core/errors/error_mapper.dart            full Sprint 04 code contract incl. VALIDATION_FAILED fix; 402 mapping
lib/core/errors/failure_message_resolver.dart calm copy for the new kinds
lib/features/reading/domain/reading_repository.dart      create(..., {idempotencyKey})
lib/features/reading/data/reading_repository_impl.dart   Idempotency-Key header
lib/features/reading/application/reading_submission_controller.dart charge-safe key cycle
lib/features/wallet/domain/wallet_repository.dart        +entitlement()
lib/features/wallet/data/wallet_repository_impl.dart     bearer identity; GET /entitlements/me
lib/features/wallet/application/wallet_controller.dart   entitlement alongside wallet
lib/features/wallet/presentation/pages/wallet_page.dart  coverage/cost line; debit/refund labels
lib/features/splash/presentation/controllers/startup_controller.dart session bootstrap
lib/app/localization/app_strings.dart        new strings (fa/en)
lib/l10n/app_en.arb, lib/l10n/app_fa.arb     arb parity for new keys
analysis_options.yaml                        formatter page_width: 100
test/core/error_mapper_test.dart             Sprint 04 code contract
test/features/reading_submission_test.dart   idempotency-cycle coverage
test/features/wallet_test.dart               entitlement coverage
test/features/ritual_submission_flow_test.dart fake aligned to new signature
```

## Root
```
Modified: package.json            test:e2e / build aliases; validate:sprint04
Modified: .github/workflows/ci.yml TELEGRAM_BOT_TOKEN for e2e
Modified: docs/PHASE1_NOTES.md    Sprint 04 execution notes
Added:    scripts/validate-sprint-04.sh
Added:    CHANGE-MANIFEST.md, SPRINT-04-REPORT.md, SPRINT-04-VALIDATION-EVIDENCE.md
```

## Known-missing (blocked, not forgotten)
```
package-lock.json — npm registry unreachable from the authoring sandbox
(403 blocked-by-allowlist). Generate on a networked machine:
    npm install --package-lock-only
The validation script hard-stops without it.
```
