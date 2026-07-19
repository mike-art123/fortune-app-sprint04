import { createHmac } from 'node:crypto';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';

/**
 * E2E helpers for the Telegram login flow (Sprint 04 / doc 53).
 *
 * The bot token must be in the environment BEFORE the Nest app compiles —
 * call `ensureTestBotToken()` at module load in every e2e spec that logs in.
 */
export const E2E_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '7654321:AAF-e2e-test-token';

export function ensureTestBotToken(): void {
  if (!process.env.TELEGRAM_BOT_TOKEN) {
    process.env.TELEGRAM_BOT_TOKEN = E2E_BOT_TOKEN;
  }
}

export interface TelegramTestUser {
  id: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  language_code?: string;
}

/** Builds initData exactly the way Telegram signs it for a Mini App. */
export function buildInitData(
  user: TelegramTestUser,
  options: { botToken?: string; authDate?: number; tamper?: boolean } = {},
): string {
  const entries: Array<[string, string]> = [
    ['auth_date', String(options.authDate ?? Math.floor(Date.now() / 1000))],
    ['query_id', `AA${Math.random().toString(36).slice(2, 10)}`],
    ['user', JSON.stringify(user)],
  ];
  const dataCheckString = entries
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join('\n');
  const secret = createHmac('sha256', 'WebAppData')
    .update(options.botToken ?? E2E_BOT_TOKEN)
    .digest();
  let hash = createHmac('sha256', secret).update(dataCheckString).digest('hex');
  if (options.tamper) {
    hash = hash.replace(/^./, hash.startsWith('0') ? '1' : '0');
  }
  const params = new URLSearchParams(entries);
  params.append('hash', hash);
  return params.toString();
}

export interface LoginSession {
  accessToken: string;
  userId: string;
  telegramId: string;
}

/** Logs a (usually fresh) Telegram user in and returns a usable bearer token. */
export async function loginAs(
  app: INestApplication,
  user: TelegramTestUser,
): Promise<LoginSession> {
  const res = await request(app.getHttpServer())
    .post('/api/v1/auth/telegram')
    .send({ initData: buildInitData(user) })
    .expect(200);
  return {
    accessToken: res.body.data.accessToken as string,
    userId: res.body.data.user.id as string,
    telegramId: res.body.data.user.telegramId as string,
  };
}

/** A unique Telegram id per test run so state never leaks between runs. */
export function freshTelegramId(): number {
  return 100_000_000 + (Date.now() % 100_000_000) * 10 + Math.floor(Math.random() * 10);
}
