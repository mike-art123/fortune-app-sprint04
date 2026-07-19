import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * Telegram Mini App initData verification (Sprint 04 / doc 53).
 *
 * The Web App passes `initData` — a querystring signed by Telegram. We rebuild
 * the data-check-string (all pairs except `hash`, sorted, joined with \n) and
 * compare HMAC-SHA256 signatures, where the secret key is
 * HMAC-SHA256(botToken) keyed with the literal string "WebAppData".
 * See https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
 *
 * Pure function: no I/O, no logging — callers must never log the raw initData
 * (it contains the user's name; privacy rule §6).
 */

export interface VerifiedInitData {
  ok: true;
  telegramId: string;
  displayName: string | null;
  languageCode: string | null;
  authDate: Date;
}

export type InitDataFailureReason =
  | 'malformed'
  | 'missing_hash'
  | 'invalid_hash'
  | 'expired'
  | 'missing_user';

export interface FailedInitData {
  ok: false;
  reason: InitDataFailureReason;
}

export type InitDataVerification = VerifiedInitData | FailedInitData;

interface TelegramWebAppUser {
  id?: unknown;
  first_name?: unknown;
  last_name?: unknown;
  username?: unknown;
  language_code?: unknown;
}

const HEX_64 = /^[0-9a-f]{64}$/;

export function verifyTelegramInitData(
  initData: string,
  botToken: string,
  options: { maxAgeSeconds: number; now?: Date },
): InitDataVerification {
  if (typeof initData !== 'string' || initData.length === 0 || initData.length > 4096) {
    return { ok: false, reason: 'malformed' };
  }

  let params: URLSearchParams;
  try {
    params = new URLSearchParams(initData);
  } catch {
    return { ok: false, reason: 'malformed' };
  }

  const hash = params.get('hash');
  if (!hash || !HEX_64.test(hash)) {
    return { ok: false, reason: 'missing_hash' };
  }

  const pairs: string[] = [];
  for (const [key, value] of params.entries()) {
    if (key !== 'hash') pairs.push(`${key}=${value}`);
  }
  pairs.sort();
  const dataCheckString = pairs.join('\n');

  const secretKey = createHmac('sha256', 'WebAppData').update(botToken).digest();
  const expected = createHmac('sha256', secretKey).update(dataCheckString).digest();
  const provided = Buffer.from(hash, 'hex');
  if (provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
    return { ok: false, reason: 'invalid_hash' };
  }

  const authDateRaw = params.get('auth_date');
  const authDateSeconds = authDateRaw ? Number.parseInt(authDateRaw, 10) : Number.NaN;
  if (!Number.isFinite(authDateSeconds) || authDateSeconds <= 0) {
    return { ok: false, reason: 'malformed' };
  }
  const nowSeconds = Math.floor((options.now ?? new Date()).getTime() / 1000);
  const CLOCK_SKEW_SECONDS = 60;
  const age = nowSeconds - authDateSeconds;
  if (age > options.maxAgeSeconds || age < -CLOCK_SKEW_SECONDS) {
    return { ok: false, reason: 'expired' };
  }

  const userRaw = params.get('user');
  if (!userRaw) {
    return { ok: false, reason: 'missing_user' };
  }
  let user: TelegramWebAppUser;
  try {
    user = JSON.parse(userRaw) as TelegramWebAppUser;
  } catch {
    return { ok: false, reason: 'malformed' };
  }
  const telegramIdNum = typeof user.id === 'number' ? user.id : Number.NaN;
  if (!Number.isSafeInteger(telegramIdNum) || telegramIdNum <= 0) {
    return { ok: false, reason: 'missing_user' };
  }

  const first = typeof user.first_name === 'string' ? user.first_name.trim() : '';
  const last = typeof user.last_name === 'string' ? user.last_name.trim() : '';
  const username = typeof user.username === 'string' ? user.username.trim() : '';
  const displayName = [first, last].filter(Boolean).join(' ') || username || null;

  return {
    ok: true,
    telegramId: String(telegramIdNum),
    displayName,
    languageCode: typeof user.language_code === 'string' ? user.language_code : null,
    authDate: new Date(authDateSeconds * 1000),
  };
}
