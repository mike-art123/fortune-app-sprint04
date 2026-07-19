# Fortune App — Monorepo (Foundation Phase 1)

Premium Persian fortune experience. Flutter client + NestJS backend, per approved docs 01–50.

## Structure
```
fortune_app/
├── apps/
│   ├── mobile/   # Flutter (Riverpod, go_router, Dio behind ApiClient)
│   └── api/      # NestJS (Prisma, Redis, BullMQ, envelope, Swagger)
├── packages/
│   ├── shared_contracts/  # API envelope + error codes (TS)
│   ├── design_tokens/     # Illuminated Sky tokens (source of truth)
│   └── lint_rules/        # shared ESLint + Dart analysis base
├── infrastructure/        # docker-compose (Postgres + Redis)
├── scripts/               # dev-up / dev-down
└── .github/workflows/     # CI
```

## Prerequisites
- Node 20+, npm 10+
- Flutter stable, Dart 3.4+
- Docker (for local Postgres + Redis)

## 1. Local infrastructure
```bash
cp .env.example apps/api/.env      # edit secrets
./scripts/dev-up.sh                # Postgres :5432, Redis :6379
```

## 2. Backend (apps/api)

NestJS foundation per Document 52: modular monolith, strict TypeScript,
Prisma/PostgreSQL, Redis, BullMQ-ready queues, structured pino logging with
redaction, request correlation, normalized error contract, Swagger, rate
limiting, idempotency + outbox + transaction abstractions, graceful shutdown.

```bash
cp apps/api/.env.example apps/api/.env    # edit values; never commit secrets
./scripts/dev-up.sh                       # Postgres :5432, Redis :6379 (healthchecked)

npm install
npm run db:generate                       # prisma generate
npm run db:migrate                        # creates infrastructure tables
npm run db:seed                           # idempotent dev seed

npm run api:dev                           # http://localhost:3000/api/v1
curl http://localhost:3000/api/v1/health/live
curl http://localhost:3000/api/v1/health/ready
# docs: http://localhost:3000/api/docs

# quality gates
npm run api:format:check && npm run api:lint && npm run api:test
npm run api:e2e                           # requires Postgres + Redis running
npm run api:build
```

**Conventions:** URI versioning `/api/v1/*`; success envelope
`{ success, data, meta: { requestId } }`; error envelope
`{ success:false, error:{ code, message, details?, retryable? }, requestId }`;
UTC ISO-8601 timestamps; opaque cursors; every request carries `x-request-id`.
The auth guard is global — routes opt out with `@Public()`. The foundation
verifier denies all tokens by design until Document 53 lands.

## 3. Mobile (apps/mobile)

Flutter: stable channel. Dart: bundled with the selected Flutter version.
SDK constraint in `pubspec.yaml` is `>=3.6.0 <4.0.0` — verify it matches your
installed toolchain and adjust if needed.

```bash
cd apps/mobile

# Native shells are generated locally (git-ignored), once per clone:
flutter create --platforms=android,ios,web .

flutter pub get
flutter gen-l10n                                    # generates ARB output
dart run build_runner build --delete-conflicting-outputs   # when codegen is used

# Quality gates
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test

# Run a flavor
flutter run -t lib/main_development.dart --dart-define=API_BASE_URL=http://localhost:3000/api/v1
flutter run -t lib/main_staging.dart
flutter run -t lib/main_production.dart
```

### Mobile architecture map
```
lib/
  app/          bootstrap, routing, theme, localization  (composition root)
  core/         config, network, errors, persistence, logging, platform
  design_system/ tokens, semantic theme, components, motion, a11y
  features/     splash, explore, ritual_entry, reading, wallet, profile
  shared/       cross-feature widgets, models, providers
```

**Binding rules**
- Features depend on `ApiClient`, never on Dio directly.
- Widgets read semantic colours via `context.fortuneColors`, never raw hex.
- User-visible text comes from `context.strings`, never hardcoded.
- Riverpod is the only DI/state system; GoRouter the only navigation system.
- Tokens are secured in secure storage; preferences in SharedPreferences.

### Package rationale
| Package | Why |
|---|---|
| flutter_riverpod | single DI + state system |
| go_router | single declarative router, deep-link ready |
| dio | single HTTP client, wrapped by `ApiClient` |
| flutter_secure_storage | credentials only |
| shared_preferences | non-sensitive preferences |
| connectivity_plus | connectivity *hint* for better error copy |
| uuid | request correlation ids |
| intl | date/number formatting |
| freezed / json_serializable | immutable models + DTO mapping (later phases) |
| mocktail | test doubles |

### Known limitations (foundation phase)
- `AppStrings` is a hand-written localization layer mirroring the ARB keys, so
  the project compiles before `flutter gen-l10n` runs. Swap to the generated
  `AppLocalizations` in one file; call sites (`context.strings`) stay unchanged.
- Analytics and crash reporting are no-op implementations by design.
- The Telegram bridge is the "unavailable" implementation; the real one lands
  with the auth phase.
- Placeholder pages are intentionally minimal and are NOT the final feature UI.

## Root commands
| Command | Action |
|---|---|
| `npm run install:all` | install API + mobile deps |
| `npm run api:dev` | run backend (watch) |
| `npm run mobile:run` | run Flutter app |
| `npm test` | backend unit tests |
| `npm run lint` | backend lint |
| `npm run format` | backend format |
| `npm run db:migrate` | Prisma migrate |
| `npm run db:generate` | Prisma generate |
| `npm run mobile:analyze` | Flutter analyzer |
| `npm run mobile:test` | Flutter tests |

## Architecture rules (enforced)
- UI → Adapter/Controller → ApiClient → NestJS. Features never import Dio directly (use `ApiClient`).
- No business logic in widgets or controllers.
- Colors/spacing/motion come from design tokens only.
- Persian-first, RTL by default.

## Notes
- Native shells (`android/ios/web`) are generated locally and git-ignored.
- Secrets never committed — only `.env.example` is tracked.
