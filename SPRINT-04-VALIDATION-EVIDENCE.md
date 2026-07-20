# SPRINT-04-VALIDATION-EVIDENCE

Authored: 2026-07-19 11:33Z, inside the Cowork sandbox.
Rule applied (working rules §6): **nothing below is reported as PASS without
captured command output.** Gates that could not execute are marked PENDING
with the exact command — never as PASS.

## 1. Environment constraint (verbatim)

The authoring sandbox has no package-registry or toolchain network access:

```
$ npm ping
npm error 403 403 Forbidden - GET https://registry.npmjs.org/-/ping

$ curl -sI https://registry.npmjs.org/        # and storage.googleapis.com (Flutter SDK)
HTTP/1.1 403 Forbidden
X-Proxy-Error: blocked-by-allowlist
```

PyPI and apt are equally blocked; `tsc`/`jest`/`eslint`/`flutter`/`dart`/
`docker`/`psql` are not installed and cannot be installed from here.
Consequently a valid `package-lock.json` (which requires registry-resolved
integrity hashes) **cannot be produced here and was not faked**.

## 2. Gates that DID run here (real output)

### 2.1 Real execution of the shipped initData verifier
`apps/api/src/modules/auth/telegram-init-data.ts` (decorator-free) was
executed unmodified via `node --experimental-strip-types` against 13
adversarial cases (valid, tampered hash, wrong bot, stale, future-dated,
missing hash/user, non-numeric id, oversize, username fallback):

```
RESULT: 13 passed, 0 failed
```

### 2.2 JWT algorithm core (plain-Node mirror of TokenService logic)
```
EdDSA sign/verify: true | tampered rejected: true | RS256 sign/verify: true
```

### 2.3 Static integrity over the final tree
```
apps/api:    254 relative imports, unresolved 0
apps/mobile: 260 relative imports, unresolved 0   (+ package:fortune_app/ paths checked)
validate-sprint-04.sh: bash -n OK
app_en.arb / app_fa.arb / package.json / apps/api/package.json: JSON OK
.github/workflows/ci.yml: YAML OK
TODO/FIXME/placeholder markers in Sprint 04 code: 0
```

## 3. Required gates — status table

| # | Gate | Command | Status |
|---|------|---------|--------|
| 1 | lockfile | `npm install --package-lock-only` | **PENDING — blocked (registry 403)** |
| 2 | clean install | `npm ci` | PENDING (needs #1) |
| 3 | prisma format | `npx --workspace apps/api prisma format` | PENDING |
| 4 | prisma validate | `npx --workspace apps/api prisma validate` | PENDING |
| 5 | prisma generate | `npm run db:generate` | PENDING |
| 6 | migration deploy | `npx --workspace apps/api prisma migrate deploy` | PENDING (needs Postgres) |
| 7 | drift vs shadow DB | `prisma migrate diff --from-migrations apps/api/prisma/migrations --to-schema-datamodel apps/api/prisma/schema.prisma --shadow-database-url $SHADOW_DATABASE_URL --exit-code` | PENDING |
| 8 | lint | `npm run lint` | PENDING |
| 9 | unit tests | `npm test` | PENDING |
| 10 | e2e tests | `npm run test:e2e` | PENDING (needs Postgres+Redis) |
| 11 | backend build | `npm run build` | PENDING |
| 12 | flutter pub get | `flutter pub get` | PENDING (no SDK here) |
| 13 | dart format check | `dart format --output=none --set-exit-if-changed .` | PENDING |
| 14 | flutter analyze | `flutter analyze` | PENDING |
| 15 | flutter test | `flutter test` | PENDING |

All fifteen are chained, in this order, by **one command** on a networked
machine with Docker + Flutter installed:

```bash
npm install --package-lock-only   # once, then commit the lockfile
npm run validate:sprint04
```

The script fails fast, creates the shadow DB, runs the drift gate against it,
refuses to call a skipped run a pass (exit 3 + explicit ⊘ lines), and prints a
✓ line per gate — that output is the completion evidence this file must be
updated with.

## 4. Honest bottom line

Implementation (backend + Flutter) is complete and internally consistent by
every check executable in this environment. Sprint 04 is **not yet
"verified complete"**: gates #1–#15 have not produced output here, and this
file says so instead of pretending otherwise.

---

# Sprint 04B — Verification Gate attempt (2026-07-19 11:43Z)

## Question A/B: Flutter authentication status → **(A) IMPLEMENTED**

The earlier "mobile still speaks x-anon-id" line described the tree BEFORE the
Flutter half landed; it was superseded in the same session and the stale note
was corrected. Implementation evidence from the CURRENT tree (grep output,
reproducible):

```
x-anon-id / anonId in apps/mobile/lib: none (one historical comment only;
    PrefKeys.anonId survives solely so the v2 migration can delete stored values)
lib/features/auth/: auth_controller, auth_repository(+impl), auth_dto,
    auth_session, access_token_claims  (+ test/features/auth_controller_test.dart)
startup_controller.dart:19,41   → authController.bootstrap() wired into startup
auth_interceptor.dart:22        → Bearer attach (now fed by real login tokens)
reading_repository_impl.dart:16 → Idempotency-Key on paid readings
wallet_repository_impl.dart     → bearer identity + GET /entitlements/me
```

This is *implementation* evidence. *Execution* evidence (analyze/test) still
requires a Flutter SDK — see below.

## Execution attempt in this session — all avenues exhausted, verbatim

Local sandbox (re-probed this session):
```
registry.npmjs.org  → HTTP/1.1 403 Forbidden (X-Proxy-Error: blocked-by-allowlist)
pypi.org            → HTTP/1.1 403 Forbidden
storage.googleapis.com (Flutter SDK) → HTTP/1.1 403 Forbidden
docker / psql / flutter / dart → not installed
```

Remote cloud agent (isolation: remote) — spawned and probed:
```
node --version → v22.22.3
npm ping       → npm error 403 403 Forbidden - GET https://registry.npmjs.org/-/ping
docker/flutter/dart/psql → not installed
```

Conclusion: no execution venue reachable from this session has registry or
toolchain access. Gates #1–#15 remain **PENDING — not failed, not passed**.
Nothing here is fabricated to look like a run.

## The two real verification venues (both fully prepared)

1. **Any networked machine** (Node ≥20, Docker, Flutter):
   ```bash
   npm install --package-lock-only     # gate 1 — commit the lockfile
   npm run validate:sprint04           # gates 2–15, fail-fast, per-gate ✓ output
   ```
2. **CI**: `.github/workflows/ci.yml` was extended in 04B so a plain push now
   executes every backend gate — npm ci, prisma validate, prisma-format-is-a-
   no-op check, generate, migrate deploy, **shadow-DB drift check
   (`migrate diff --exit-code` against a real empty `fortune_shadow`)**,
   format, lint, unit, e2e, build — plus the full Flutter job (pub get,
   gen-l10n, format check, analyze, test). Green CI on both jobs == Sprint 04
   verified. (CI's `npm ci` also requires the lockfile from gate 1 first.)

## 04B verdict

- Backend + Flutter implementation: **consistent with the Sprint 04 auth
  architecture** (answer A), by mechanical inspection of the final tree.
- **The Sprint 04 implementation is feature-complete. Production verification
  remains pending until the complete validation pipeline has been executed
  successfully in a fully provisioned environment.** This session (re-checked
  once more at closing: `npm ping` → E403) provides no such environment; the
  two prepared venues are a provisioned local machine
  (`npm install --package-lock-only && npm run validate:sprint04`, which now
  also runs `flutter doctor` first among the mobile gates) or CI on push.
- Failure-classification protocol for the first run: each failing gate is to
  be labeled implementation defect / environment issue / configuration issue /
  pre-existing issue, and only genuine Sprint 04 defects fixed. Two known
  candidates are pre-classified above: a `dart format` diff (pre-existing —
  the formatter never ran on this tree) and any `migrate diff` drift
  (implementation defect in the hand-written migration — regenerate via
  `prisma migrate diff --from-empty --to-schema-datamodel`).

---

# Sprint 04B — GitHub Actions execution attempt (2026-07-19, live run)

## What was actually done (real actions, not simulated)

1. Created private GitHub repo `mike-art123/fortune-app-sprint04`, pushed the
   full tree (313+ files, verified via GitHub's own file browser and commit
   count: 1 → 4 commits over the session).
2. Added `.github/workflows/bootstrap-lockfile.yml` (auto-generates
   `package-lock.json` on a runner, since no local/sandbox venue has npm
   registry access — see prior section) and confirmed `ci.yml` is the full
   15-gate backend+Flutter pipeline described above.
3. Pushed 4 separate commits, each intended to trigger the workflows via
   `on: push`. Checked run status after every push via GitHub's own pages
   (fetched directly, not guessed):
   - Run #1 (Initial commit) → **Startup failure**, 0 jobs, listed as
     "(Unnamed workflow)"
   - Run #2 (Create bootstrap-lockfile.yml) → **Startup failure**, same signature
   - Run #3 (Create SPRINT-04B-TRIGGER.md) → **Startup failure**, same signature
4. Hypothesis tested: private-repo Actions billing/startup quirk. Repo was
   switched from private → **public** by the repo owner as a diagnostic step.
5. Pushed a 4th commit after the visibility change. Result: **Startup
   failure again**, same "(Unnamed workflow)" signature, 0 jobs — ruling out
   the private-repo hypothesis.
6. Checked each named workflow's own run history directly
   (`/actions/workflows/ci.yml` and `/actions/workflows/bootstrap-lockfile.yml`):
   both report **"This workflow has no runs yet" / 0 workflow runs** — i.e.
   none of the 4 "Startup failure" runs are attributed to either workflow
   file GitHub can identify. This means GitHub's control plane is rejecting
   the run before it gets far enough to parse/associate the triggering
   workflow YAML at all.
7. Checked `githubstatus.com` API (`/api/v2/status.json`) at the time of
   failure: `"indicator":"none"`, `"description":"All Systems Operational"` —
   not a GitHub-wide outage.
8. Checked repo Settings → Actions → General (screenshot confirmed by repo
   owner): **"Allow all actions and reusable workflows"** is selected (the
   most permissive setting), "Require actions to be pinned to a full-length
   commit SHA" is unchecked. Repo-level Actions permissions are not the
   cause.

## Root-cause classification: **INFRASTRUCTURE (GitHub account-level), not a Sprint 04 defect**

The exact signature observed — `startup_failure` with zero jobs, workflow
run unattributed to any named workflow file, occurring on every push
regardless of repo visibility or workflow content — matches a
well-documented GitHub anti-abuse pattern: **GitHub Actions being
automatically restricted at the account level for new/low-activity
accounts**, to prevent abuse (e.g. crypto-mining via free CI minutes). This
is applied before the workflow file is even read, which is why it doesn't
matter that `ci.yml` and `bootstrap-lockfile.yml` are both valid,
both correctly configured, and Actions permissions are set to "allow all."

This is a control-plane decision on GitHub's side tied to the `mike-art123`
account, not to this repository's code, workflow YAML, or configuration.
None of the Sprint 04 or 04B code is implicated.

## What resolves this (outside this session's control)

- GitHub Support can lift the restriction manually (repo owner needs to
  open a support ticket referencing the account and repo).
- It sometimes self-resolves after a period of ordinary account activity
  (no fixed SLA published by GitHub).
- Verifying a payment method / phone number on the account is reported by
  other users to sometimes trigger auto-approval.

## Sprint 04B status

**Still open.** Every gate remains PENDING — not fabricated as passing.
The implementation is code-complete (backend + Flutter) and the CI
pipeline is fully authored and would run all 15 gates the moment GitHub
allows a job to actually start on this account. The only remaining blocker
is the GitHub account-level Actions restriction described above, which
requires the repo owner's direct action with GitHub (this cannot be done
by an agent — it requires GitHub Support / account verification on the
owner's side).

---

# Policy update (2026-07-20)

Per explicit user instruction, development is no longer blocked on GitHub
Actions completing. Two runs (Bootstrap lockfile #2, CI #2 — commit
299226b) remain **Queued** on GitHub's side (account-level runner
provisioning delay following the GitHub Pro upgrade; workflow attribution
and job-graph parsing now work correctly, confirming the earlier
account-level Actions restriction is resolved — only runner allocation
latency remains). These will be rechecked periodically. Sprint 04B
verification (a real green run of every gate) is still open and will be
completed once a runner picks up a queued run — this does not block
further development work per the user's instruction above.

---

# Sprint 04B — First real CI run + failure classification (2026-07-20)

Runner queue drained after the GitHub Pro upgrade. Real runs at last:

- **Bootstrap lockfile #1** — SUCCESS: generated and committed
  `package-lock.json` on a runner (commit pulled back into main). Gate #1
  (lockfile) is now CLOSED.
- **CI #3** (commit 4ae67bd, lockfile + polish present) — **FAILURE**, two
  gates, both classified per the 04B protocol from the actual step logs:

## Failure 1 — api job, step "prisma migrate diff" (drift gate)
```
Error: Could not load `--to-schema-datamodel` from provided path
`apps/api/prisma/schema.prisma`: file or directory not found
```
Classification: **CONFIGURATION issue** (in ci.yml itself), not an
implementation defect. `npx --workspace apps/api` runs with the workspace
directory as cwd, so the explicit `apps/api/...` paths resolved to
`apps/api/apps/api/...`. Every earlier prisma step passed because they rely
on default schema discovery relative to the same cwd. The drift gate itself
never actually executed — no drift has been observed yet.
Fix applied (minimal): drop the doubled `apps/api/` prefix in ci.yml and in
scripts/validate-sprint-04.sh (`prisma/migrations`, `prisma/schema.prisma`).

## Failure 2 — mobile job, step "flutter pub get"
```
Note: intl is pinned to version 0.20.2 by flutter_localizations from the
flutter SDK. ... fortune_app depends on intl ^0.19.0, version solving failed.
```
Classification: **ENVIRONMENT/dependency-constraint issue**, not an
implementation defect. The current stable Flutter SDK pins intl to 0.20.2
via flutter_localizations; the pubspec constraint (^0.19.0) predates that.
`package:intl` is not imported directly anywhere in apps/mobile/lib, so the
bump is behavior-neutral for our code.
Fix applied (minimal, exactly pub's own suggestion): `intl: ^0.20.2`.

## Also fixed in the same pass
Non-blocking runner warning: actions pinned to Node 20 are being force-run
on Node 24 (Node 20 deprecated on GitHub runners, Sep 2025 changelog). Left
as-is for now — warning only, does not affect gate outcomes.

Both fixes pushed; awaiting the next CI run for the verdict. All remaining
gates past `npm ci` / `pub get` have still never produced output — they are
PENDING, not passed.
