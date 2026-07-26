/**
 * BakhtNegar — smart-notification sweep scheduler (scope §7).
 *
 * This Worker is a clock and nothing else. Every decision about *whether* a
 * person should be messaged — their quiet hours, their time zone, the daily
 * cap, an active mute, and the once-per-kind-per-day rule — lives in the API
 * and stays there. Re-implementing any of it here would create two sources of
 * truth, and sooner or later one of them would be wrong at 3 a.m. in somebody
 * else's country.
 *
 * Why every fifteen minutes: quiet hours are per-reader and per-time-zone, so
 * the only way a reader in Tehran and a reader in Toronto both get a morning
 * that is actually morning is to look often and let the API answer "not yet"
 * almost every time. A pass that sends nothing costs one request.
 *
 * Why retrying is safe: the API writes a delivery row keyed
 * `(user, kind, dateKey)` with a unique index *before* it calls Telegram, so a
 * pass that runs twice — or two passes racing — cannot message the same person
 * twice for the same reason on the same local day.
 */

/** Three tries inside one pass; after that the next cron tick is soon enough. */
const MAX_ATTEMPTS = 3;
const BACKOFF_MS = [2_000, 6_000];

/**
 * The API cancels its own handler at 30s (`REQUEST_TIMEOUT_MS`). Waiting past
 * that means a server-side timeout arrives as a real answer instead of being
 * masked by a client-side guess.
 */
const REQUEST_TIMEOUT_MS = 45_000;

export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(sweep(env, event.scheduledTime));
  },
};

async function sweep(env, scheduledTime) {
  const url = requireUrl(env.SWEEP_URL);
  const secret = env.NOTIFICATIONS_SWEEP_SECRET;

  if (typeof secret !== 'string' || secret.length === 0) {
    // Fail loudly rather than send an unauthenticated request that would be
    // refused anyway. A missing secret is a deployment mistake, not a runtime
    // condition to swallow.
    throw new Error('NOTIFICATIONS_SWEEP_SECRET is not bound to this Worker');
  }

  let lastStatus = 0;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    let response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          // The secret travels in a header, never in the path or the query, so
          // it cannot end up in an access log, a referrer, or a browser
          // history. `Content-Length: 0` because the route takes no body.
          'x-sweep-secret': secret,
          'content-length': '0',
          'user-agent': 'bakhtnegar-notifications-sweep/1',
        },
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
    } catch (error) {
      // A refused connection or a client-side timeout. Worth another try.
      if (attempt === MAX_ATTEMPTS) {
        throw new Error(`sweep unreachable after ${attempt} attempts: ${reason(error)}`);
      }
      await pause(BACKOFF_MS[attempt - 1]);
      continue;
    }

    lastStatus = response.status;

    if (response.ok) {
      // The body carries counts only — no names, no message text, no user ids.
      const counts = await readCounts(response);
      console.log(
        JSON.stringify({
          event: 'sweep.ok',
          scheduledTime: new Date(scheduledTime).toISOString(),
          attempt,
          ...counts,
        }),
      );
      return;
    }

    if (!retryable(response.status)) {
      // 403 means the secret is wrong or unset on the API side, and 429 means
      // the throttle is holding. Neither improves by asking again within the
      // same pass; both are fixed by a person or by waiting for the next tick.
      throw new Error(`sweep refused with ${response.status} (not retried)`);
    }

    if (attempt === MAX_ATTEMPTS) break;
    await pause(BACKOFF_MS[attempt - 1]);
  }

  throw new Error(`sweep failed after ${MAX_ATTEMPTS} attempts, last status ${lastStatus}`);
}

/** 408 and 5xx are the server saying "not now"; everything else is an answer. */
function retryable(status) {
  return status === 408 || status >= 500;
}

/**
 * Refuses a URL that carries a query string. The secret belongs in a header,
 * and this makes "just put the token in the URL" fail at deploy time rather
 * than quietly leak into every log the request passes through.
 */
function requireUrl(raw) {
  if (typeof raw !== 'string' || raw.length === 0) {
    throw new Error('SWEEP_URL is not configured');
  }
  const url = new URL(raw);
  if (url.protocol !== 'https:') throw new Error('SWEEP_URL must be https');
  if (url.search !== '') throw new Error('SWEEP_URL must not carry a query string');
  return url.toString();
}

async function readCounts(response) {
  try {
    const payload = await response.json();
    const data = payload?.data ?? payload;
    return {
      considered: data?.considered ?? null,
      sent: data?.sent ?? null,
      skipped: data?.skipped ?? null,
    };
  } catch {
    // A 200 with an unreadable body is still a successful pass; do not turn a
    // parsing detail into a failed job.
    return { considered: null, sent: null, skipped: null };
  }
}

function reason(error) {
  return error instanceof Error ? error.name : 'unknown';
}

function pause(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
