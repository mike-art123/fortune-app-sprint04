import { createHmac } from 'node:crypto';
import { verifyTelegramInitData } from './telegram-init-data';

const BOT_TOKEN = '7654321:AAF-test-bot-token';

/** Builds a correctly signed initData string the way Telegram would. */
function buildInitData(options: {
  botToken?: string;
  user?: Record<string, unknown> | null;
  authDate?: number;
  tamper?: boolean;
}): string {
  const authDate = options.authDate ?? Math.floor(Date.now() / 1000);
  const entries: Array<[string, string]> = [
    ['auth_date', String(authDate)],
    ['query_id', 'AAtest'],
  ];
  if (options.user !== null) {
    entries.push([
      'user',
      JSON.stringify(options.user ?? { id: 42, first_name: 'سارا', language_code: 'fa' }),
    ]);
  }

  const dataCheckString = entries
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join('\n');
  const secret = createHmac('sha256', 'WebAppData')
    .update(options.botToken ?? BOT_TOKEN)
    .digest();
  let hash = createHmac('sha256', secret).update(dataCheckString).digest('hex');
  if (options.tamper) {
    hash = hash.replace(/^./, hash.startsWith('0') ? '1' : '0');
  }

  const params = new URLSearchParams(entries);
  params.append('hash', hash);
  return params.toString();
}

describe('verifyTelegramInitData', () => {
  const maxAge = { maxAgeSeconds: 3600 };

  it('accepts a correctly signed, fresh initData and extracts the identity', () => {
    const result = verifyTelegramInitData(buildInitData({}), BOT_TOKEN, maxAge);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.telegramId).toBe('42');
      expect(result.displayName).toBe('سارا');
      expect(result.languageCode).toBe('fa');
    }
  });

  it('rejects a tampered hash', () => {
    const result = verifyTelegramInitData(buildInitData({ tamper: true }), BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'invalid_hash' });
  });

  it('rejects initData signed by a different bot token', () => {
    const forged = buildInitData({ botToken: '1111111:other-bot' });
    const result = verifyTelegramInitData(forged, BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'invalid_hash' });
  });

  it('rejects stale initData beyond the max age', () => {
    const stale = buildInitData({ authDate: Math.floor(Date.now() / 1000) - 7200 });
    const result = verifyTelegramInitData(stale, BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'expired' });
  });

  it('rejects initData stamped in the future beyond clock skew', () => {
    const future = buildInitData({ authDate: Math.floor(Date.now() / 1000) + 3600 });
    const result = verifyTelegramInitData(future, BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'expired' });
  });

  it('rejects a payload without a hash', () => {
    const result = verifyTelegramInitData('auth_date=1&user=%7B%7D', BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'missing_hash' });
  });

  it('rejects a signed payload that carries no user', () => {
    const result = verifyTelegramInitData(buildInitData({ user: null }), BOT_TOKEN, maxAge);
    expect(result).toEqual({ ok: false, reason: 'missing_user' });
  });

  it('rejects a user without a positive integer id', () => {
    const result = verifyTelegramInitData(
      buildInitData({ user: { id: 'not-a-number', first_name: 'x' } }),
      BOT_TOKEN,
      maxAge,
    );
    expect(result).toEqual({ ok: false, reason: 'missing_user' });
  });

  it('rejects empty and oversized inputs as malformed', () => {
    expect(verifyTelegramInitData('', BOT_TOKEN, maxAge)).toEqual({
      ok: false,
      reason: 'malformed',
    });
    expect(verifyTelegramInitData('a'.repeat(5000), BOT_TOKEN, maxAge)).toEqual({
      ok: false,
      reason: 'malformed',
    });
  });

  it('falls back to the username when no names are present', () => {
    const result = verifyTelegramInitData(
      buildInitData({ user: { id: 7, username: 'mahtab' } }),
      BOT_TOKEN,
      maxAge,
    );
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.displayName).toBe('mahtab');
  });
});
