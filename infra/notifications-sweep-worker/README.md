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

## Deploy

```bash
cd infra/notifications-sweep-worker

# 1. authenticate once
npx wrangler login

# 2. bind the secret — encrypted at rest, never readable again, never in Git
npx wrangler secret put NOTIFICATIONS_SWEEP_SECRET
#    paste the 64-char value when prompted, or:  npx wrangler secret put NOTIFICATIONS_SWEEP_SECRET < secret.txt

# 3. ship
npx wrangler deploy
```

The same value must already be set on Railway as `NOTIFICATIONS_SWEEP_SECRET`
(service `fortune-app-sprint04`, environment `production`).

## Verify, in the order that risks least

There is **one Railway environment (`production`)** — no staging exists — so
"test in staging first" is not available here. What replaces it is that the
feature flag makes production itself safe to test against:

**1. Chain test, zero messages.** With the flag `notifications.smart` off (its
default), `sweep()` returns `{considered:0,sent:0,skipped:0}` without reading a
single user. So a successful pass proves Cron → Worker → Railway → secret
check → sweep, while it is impossible for anyone to be messaged.

```bash
npx wrangler dev --test-scheduled          # then, in another shell:
curl "http://localhost:8787/__scheduled?cron=*/15+*+*+*+*"
npx wrangler tail                          # after deploy, watch the real ticks
```

Expect a `sweep.ok` log line with `considered: 0`.

**2. Selection and Telegram.** Only this last hop needs the flag on. Turn it on
deliberately and watch:

```sql
insert into feature_flags (key, enabled) values ('notifications.smart', true)
  on conflict (key) do update set enabled = true;
```

The flag is cached in Redis for 30s, so allow half a minute. Turning it off is
the same statement with `false` and is the fastest kill switch — faster than
touching the Worker.

Note this is a real send to real readers, so pick the moment: with default
preferences nobody is eligible between 22:00 and 08:00 Tehran time, and the cap
of 1 means at most one message per reader per day.

## Two limits worth knowing before there are many readers

- **The sweep does not paginate.** It takes the oldest `NOTIFICATIONS_SWEEP_BATCH`
  users by `createdAt` (default 200) on every pass, with no cursor. Past 200
  onboarded readers, the ones after the first 200 are never considered.
- **200 readers may not fit in 30s.** Each is two queries plus a possible
  Telegram call, against a 30s request timeout. The unique index means a
  timeout is harmless — the pass simply stops partway and the next tick
  continues — but it is worth watching `considered` against the real user
  count.

Neither blocks launch at today's size. Both want a cursor before it grows.
