# Notification sweep scheduler (scope §7)

A Cloudflare Worker whose only job is to call the API's sweep route on a
schedule. It holds no logic about who gets messaged — see `src/index.js` for
why that separation is deliberate.

## The endpoint it calls

| | |
|---|---|
| Method | `POST` |
| URL | `https://fortune-app-sprint04-production.up.railway.app/api/v1/notifications/sweep` |
| Auth | header `x-sweep-secret: <64-char secret>`, compared with `timingSafeEqual` after a length check |
| Body | none (`Content-Length: 0`) |
| Success | `200` with `{"success":true,"data":{"considered":N,"sent":N,"skipped":N},"meta":{"requestId":"…"}}` |
| Refusal | `403` `{"success":false,"error":{"code":"FORBIDDEN",…}}` — identical whether the secret is wrong or the API has none configured, on purpose |
| Throttle | 6 requests / 60s per IP (`@Throttle`) |
| Server timeout | 30s (`REQUEST_TIMEOUT_MS`), after which the request returns `408` |

Defined in `apps/api/src/modules/notifications/notifications.controller.ts`.
The route is `@Public()`, so no JWT is involved: the shared secret is the only
door, and while `NOTIFICATIONS_SWEEP_SECRET` is empty on the API the route
refuses everyone, including callers already inside the network.

## Why retrying is safe

`NotificationsService.deliver()` writes a `NotificationDelivery` row —
unique on `(userId, kind, dateKey)` — **before** it calls Telegram. A duplicate
insert throws, the send is skipped, and the pass moves on. So a retried pass,
two overlapping passes, or a pass the client gave up on mid-flight cannot
produce a second message for the same person, same reason, same local day.

`dateKey` is computed in *the reader's own* time zone, so "same day" means
their day, not UTC's.

## What the API decides, and the Worker must never second-guess

Everything, in `notification-plan.ts`:

- **mute** — an active `mutedUntil` ends the pass for that reader
- **quiet hours** — default 22:00–08:00, evaluated against their local hour, and the window is allowed to cross midnight
- **time zone** — default `Asia/Tehran`, per reader
- **daily cap** — default 1; already-sent kinds for today are subtracted
- **priority** — streak → daily → weekly, so the cap spends on the most useful one
- **streak rule** — fires when the gap since the last reading is `>= 3` days and `gap % 7 === 3`, so it nudges without nagging

Running every 15 minutes is what makes per-reader quiet hours work at all: the
API is asked often and answers "not yet" nearly every time.

## How it is deployed

Cloudflare builds it straight from GitHub — there is no local `wrangler` step,
and the owner's machine has no Node at all. That is the point: `wrangler.toml`
in this folder stays the single source of truth, so changing the schedule or
the URL is a commit, not a click.

| Setting | Value |
|---|---|
| Worker | `bakhtnegar-notifications-sweep` |
| Repository | `mike-art123/fortune-app-sprint04`, branch `main` |
| Root directory (Cloudflare calls it *Path*) | `/infra/notifications-sweep-worker` |
| Build command | **empty — leave it empty** |
| Deploy command | `npx wrangler deploy` |

The build command matters. Cloudflare defaults it to `npm run build`, which at
the repository root is an npm-workspaces fan-out: it tries to build the NestJS
API, fails on 19 TypeScript errors because Prisma has not been generated, and
takes the Worker down with it. This Worker has no dependencies and needs no
build — clearing the field is the fix.

`NOTIFICATIONS_SWEEP_SECRET` is set in the dashboard under **Settings →
Variables and secrets** with type **Secret**, never as a `[vars]` entry.
Cloudflare stores it encrypted and will not show it again; changing it later
means **Rotate**, not edit. The same value must be set on Railway
(service `fortune-app-sprint04`, environment `production`) — if the two ever
drift apart the symptom is exactly the log line
`sweep refused with 403 (not retried)`.

## Verify, in the order that risks least

There is **one Railway environment (`production`)** — no staging exists — so
"test in staging first" is not available here. What replaces it is that the
feature flag makes production itself safe to test against.

**1. Chain test, zero messages.** With the flag `notifications.smart` off (its
default), `sweep()` returns `{considered:0,sent:0,skipped:0}` without reading a
single user. So a successful pass proves Cron → Worker → Railway → secret
check → sweep, while it is impossible for anyone to be messaged.

Done on 2026-07-26. The 17:45 PDT tick logged, on the first attempt:

```json
{ "event": "sweep.ok", "attempt": 1, "considered": 0, "sent": 0, "skipped": 0 }
```

Watch it under **Observability → Logs** in the dashboard; every tick writes one
line, and a failure writes the reason rather than a stack trace.

**2. Selection and Telegram.** Only this last hop needs the flag on. Turn it on
deliberately and watch:

```sql
insert into feature_flags (key, enabled, note, updated_at)
values ('notifications.smart', true, 'smart notifications on', now())
on conflict (key) do update set enabled = true, updated_at = now();
```

`updated_at` is not optional. Prisma declares it `@updatedAt`, which it fills
in application code — the column itself is `NOT NULL` with **no** database
default, so raw SQL that omits it fails outright. The same applies to any other
flag added by hand.

Run it from **Railway → Postgres → Console**, where `psql` is already
authenticated; the Data tab's browser connection is slower to come up.

The flag is cached in Redis for 30s, so allow half a minute. The kill switch is
one statement and does not need a deploy:

```sql
update feature_flags set enabled = false, updated_at = now()
where key = 'notifications.smart';
```

Note this is a real send to real readers, so pick the moment: with default
preferences nobody is eligible between 22:00 and 08:00 Tehran time, and the cap
of 1 means at most one message per reader per day.

## The one limit left

- **A pass is bounded by time, not by reader count.** It walks a cursor through
  every onboarded reader and stops when the table is exhausted or
  `NOTIFICATIONS_SWEEP_BUDGET_MS` (60s) runs out — comfortably under the
  server's own 80s request timeout, so the sweep ends itself rather than being
  cut off mid-page. The log line carries `exhausted`, so a pass that ran out of
  room says so instead of looking complete.

  Stopping early costs nothing: the delivery row is unique on
  `(user, kind, local day)`, so the next tick re-walks from the start, serves
  everyone still owed a message, and is rejected by the index for everyone
  already served.

  At roughly two queries per reader that is several thousand readers per pass.
  If `exhausted: false` starts appearing in the logs, the fix is to batch the
  per-reader queries — not to raise the budget past the request timeout.
