# Sprint 04B — CI trigger

This file exists to trigger the full CI run after the bootstrap workflow
committed `package-lock.json` (pushes made with GITHUB_TOKEN do not trigger
workflows, so a human-authored push is needed once).

Trigger sequence:
1. Initial push — CI failed at `npm ci` (no lockfile; expected, documented).
2. `bootstrap-lockfile.yml` generated and committed the lockfile on a runner.
3. This commit — full gate run with the lockfile present.
