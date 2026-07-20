#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Official Sprint 04 validation — identity / entitlements / atomic debit,
# backend AND Flutter integration. Fail-fast, honest reporting.
#
# Gates, in order:
#   backend : npm ci → prisma format → prisma validate → prisma generate
#             → format:check → lint → unit tests → build
#   infra   : postgres+redis up → prisma migrate deploy
#             → migration drift check against a real shadow database
#             → e2e tests
#   flutter : pub get → dart format check → gen-l10n → analyze → test
#
# Environment knobs (each skip is REPORTED, never silent):
#   SKIP_E2E=1      skip infra + migrate + drift + e2e
#   SKIP_MOBILE=1   skip the Flutter gates (e.g. no SDK on this machine)
#   DATABASE_URL / SHADOW_DATABASE_URL / REDIS_HOST overrides
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/.."

PASS=()
SKIPPED=()
step() {
  local name="$1"
  shift
  echo ""
  echo "━━━ [sprint04] $name"
  "$@"
  PASS+=("$name")
}

# ── Preconditions ────────────────────────────────────────────────────────────
command -v node >/dev/null || { echo "BLOCKER: node is not installed"; exit 1; }
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "BLOCKER: Node >= 20 required (found $(node --version))"; exit 1
fi

if [ ! -f package-lock.json ]; then
  cat >&2 <<'MSG'
BLOCKER: package-lock.json is missing, so `npm ci` cannot run.
Generate and commit it on a machine with npm registry access:

    npm install --package-lock-only
    git add package-lock.json && git commit -m "chore: commit lockfile"

Then re-run this script.
MSG
  exit 1
fi

# ── Backend pipeline ─────────────────────────────────────────────────────────
step "npm ci"             npm ci
step "prisma format"      npx --workspace apps/api prisma format
step "prisma validate"    npx --workspace apps/api prisma validate
step "prisma generate"    npm run db:generate
step "format check"       npm run api:format:check
step "lint"               npm run lint
step "unit tests"         npm test
step "backend build"      npm run build

# ── Infra, migrations, drift, e2e ────────────────────────────────────────────
if [ "${SKIP_E2E:-0}" != "1" ]; then
  export NODE_ENV="${NODE_ENV:-test}"
  export DATABASE_URL="${DATABASE_URL:-postgresql://fortune:fortune@localhost:5432/fortune_dev?schema=public}"
  export SHADOW_DATABASE_URL="${SHADOW_DATABASE_URL:-postgresql://fortune:fortune@localhost:5432/fortune_shadow?schema=public}"
  export REDIS_HOST="${REDIS_HOST:-localhost}"
  # e2e signs real Telegram initData against this token (any value works).
  export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-7654321:AAF-local-validation-token}"

  if command -v docker >/dev/null; then
    step "infra up (postgres+redis)" ./scripts/dev-up.sh
    echo "━━━ [sprint04] shadow database"
    docker compose exec -T postgres \
      psql -U fortune -d fortune_dev -c 'CREATE DATABASE fortune_shadow' 2>/dev/null \
      || echo "shadow database already exists"
    PASS+=("shadow database")
  else
    echo "NOTE: docker not found — assuming Postgres/Redis and the shadow DB already exist."
  fi

  step "prisma migrate deploy" npx --workspace apps/api prisma migrate deploy

  # No drift: replaying the committed migrations onto a REAL empty shadow
  # database must reproduce schema.prisma exactly (exit code 0).
  # Paths relative to apps/api: `npx --workspace apps/api` runs with the
  # workspace directory as cwd.
  step "migration drift check" npx --workspace apps/api prisma migrate diff \
    --from-migrations prisma/migrations \
    --to-schema-datamodel prisma/schema.prisma \
    --shadow-database-url "$SHADOW_DATABASE_URL" \
    --exit-code

  step "e2e tests" npm run test:e2e
else
  SKIPPED+=("infra" "prisma migrate deploy" "migration drift check" "e2e tests")
fi

# ── Flutter gates (Sprint 04 includes the mobile integration) ────────────────
if [ "${SKIP_MOBILE:-0}" != "1" ]; then
  command -v flutter >/dev/null || {
    echo "BLOCKER: the Flutter SDK is required for Sprint 04 validation."
    echo "Install it, or run with SKIP_MOBILE=1 (the skip is recorded, not silent)."
    exit 1
  }
  pushd apps/mobile >/dev/null
  step "flutter doctor"     flutter doctor
  step "flutter pub get"    flutter pub get
  # format gate BEFORE gen-l10n: judge committed sources only, not the
  # generated app_localizations*.dart
  step "dart format check"  dart format --output=none --set-exit-if-changed .
  step "flutter gen-l10n"   flutter gen-l10n
  step "flutter analyze"    flutter analyze
  step "flutter test"       flutter test
  popd >/dev/null
else
  SKIPPED+=("flutter doctor" "flutter pub get" "flutter gen-l10n" "dart format check" "flutter analyze" "flutter test")
fi

# ── Honest summary ───────────────────────────────────────────────────────────
echo ""
if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "━━━ Sprint 04 validation: PASSED WITH SKIPS — NOT a full pass"
  printf '  ✓ %s\n' "${PASS[@]}"
  printf '  ⊘ SKIPPED: %s\n' "${SKIPPED[@]}"
  exit 3
fi
echo "━━━ Sprint 04 validation: ALL GATES PASSED"
printf '  ✓ %s\n' "${PASS[@]}"
