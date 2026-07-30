import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import {
  ensureTestBotToken,
  freshTelegramId,
  loginAs,
  type LoginSession,
} from './support/telegram-auth';

ensureTestBotToken();
// Gate readings for THIS suite only. afterAll deletes the flips so any later
// spec file in the same worker boots with the shared test defaults again.
process.env.ENFORCE_ACCESS_LIMITS = 'true';
process.env.ACCESS_UNLIMITED_PLATFORMS = 'android';

// Imported after the env is prepared.
import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

/**
 * Platform-aware enforcement (decision 2026-07-30): with gating ON, a client
 * that has no ad surface (`x-platform: android`) is never dead-ended, while
 * the web client keeps the free → ad → 402 ladder.
 * Requires PostgreSQL + Redis (docker compose up) and a migrated database.
 */
describe('access limits (e2e) — platform-aware enforcement', () => {
  let app: INestApplication;
  let session: LoginSession;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
    session = await loginAs(app, { id: freshTelegramId(), first_name: 'آزمونگر' });
  });

  afterAll(async () => {
    delete process.env.ENFORCE_ACCESS_LIMITS;
    delete process.env.ACCESS_UNLIMITED_PLATFORMS;
    await app.close();
  });

  const authed = {
    get authorization() {
      return `Bearer ${session.accessToken}`;
    },
  };

  it('web: the free daily hafez readings pass, then 402 without an ad', async () => {
    for (let i = 0; i < 2; i++) {
      await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed)
        .set('x-platform', 'web')
        .send({ fortuneId: 'hafez', input: {} })
        .expect(201);
    }

    const blocked = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .set('x-platform', 'web')
      .send({ fortuneId: 'hafez', input: {} })
      .expect(402);
    expect(blocked.body.error.code).toBe('ACCESS_REQUIRED');
  });

  it('web: a zero-allowance fortune is gated immediately', async () => {
    const blocked = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .set('x-platform', 'web')
      .send({ fortuneId: 'tarot', input: {} })
      .expect(402);
    expect(blocked.body.error.code).toBe('ACCESS_REQUIRED');
  });

  it('android: stays unlimited (no ad surface in the v1 build)', async () => {
    for (let i = 0; i < 3; i++) {
      await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed)
        .set('x-platform', 'android')
        .send({ fortuneId: 'tarot', input: {} })
        .expect(201);
    }
  });

  it('android: an absent header still counts as gated (no spoof by omission)', async () => {
    const blocked = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .send({ fortuneId: 'rune', input: {} })
      .expect(402);
    expect(blocked.body.error.code).toBe('ACCESS_REQUIRED');
  });
});
