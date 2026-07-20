# Sprint 04B — CI trigger

This file exists to trigger the full CI run after the bootstrap workflow
committed `package-lock.json` (pushes made with GITHUB_TOKEN do not trigger
workflows, so a human-authored push is needed once).

Trigger sequence:
1. Initial push — CI failed at `npm ci` (no lockfile; expected, documented).
2. `bootstrap-lockfile.yml` generated and committed the lockfile on a runner.
3. This commit — full gate run with the lockfile present.

4. Repository switched to public (Actions startup failures on private repo —
   diagnosing account/billing vs service outage). This commit retriggers both
   workflows after the visibility change.


5. Account upgraded to GitHub Pro (2026-07-19). Retriggering both workflows to test whether the account-level Actions restriction is lifted now that the account is on a paid plan.

6. Previous two queued runs got permanently stuck in "Queued" (never started, 18+ minutes) and were cancelled. Retriggering with a fresh push per GitHub's own stuck-queue guidance.