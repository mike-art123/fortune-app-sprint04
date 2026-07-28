import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { ensureTestBotToken, freshTelegramId, loginAs } from './support/telegram-auth';

ensureTestBotToken();

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

/** Requires PostgreSQL + Redis (docker compose up) and a migrated database. */
describe('entitlements (e2e) — Sprint 04', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('refuses an unauthenticated caller with the 401 contract', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/entitlements/me').expect(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('reports free coverage for a user without a subscription', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'رایگان' });

    const res = await request(app.getHttpServer())
      .get('/api/v1/entitlements/me')
      .set('authorization', `Bearer ${session.accessToken}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.covered).toBe(true);
    expect(res.body.data.source).toBe('free');
    expect(res.body.data.cost).toBe(0);
  });

  it('creates a reading without any coin debit (coins removed)', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'بی‌سکه' });
    const auth = { authorization: `Bearer ${session.accessToken}` };

    await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'hafez', input: {} })
      .expect(201);

    const wallet = await request(app.getHttpServer()).get('/api/v1/wallet').set(auth).expect(200);
    const debit = wallet.body.data.transactions.find((t: { kind: string }) => t.kind === 'debit');
    expect(debit).toBeUndefined();
  });

  describe('access options (free daily / rewarded ad / VIP — never coins)', () => {
    it('hafez starts free: unused daily allowance, backend-computed reset', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'سهمیه' });

      const res = await request(app.getHttpServer())
        .get('/api/v1/access-options/hafez')
        .set('authorization', `Bearer ${session.accessToken}`)
        .expect(200);

      const view = res.body.data;
      expect(view.accessState).toBe('free');
      expect(view.isFreeNow).toBe(true);
      expect(view.freeUsesRemainingToday).toBe(2);
      expect(new Date(view.nextFreeResetAt).getTime()).toBeGreaterThan(Date.now());
      expect(view).not.toHaveProperty('coinCost');
      expect(view).not.toHaveProperty('coinBalance');
    });

    it('hafez has two free per day; daily always needs an ad', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'مستقل' });
      const auth = { authorization: `Bearer ${session.accessToken}` };

      await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(auth)
        .send({ fortuneId: 'hafez', input: {} })
        .expect(201);

      const hafez = await request(app.getHttpServer())
        .get('/api/v1/access-options/hafez')
        .set(auth)
        .expect(200);
      expect(hafez.body.data.isFreeNow).toBe(true);
      expect(hafez.body.data.freeUsesRemainingToday).toBe(1);

      const daily = await request(app.getHttpServer())
        .get('/api/v1/access-options/daily')
        .set(auth)
        .expect(200);
      expect(daily.body.data.isFreeNow).toBe(false);
      expect(daily.body.data.freeUsesRemainingToday).toBe(0);
    });

    it('an unknown fortune yields the 404 contract', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'ناشناس' });

      const res = await request(app.getHttpServer())
        .get('/api/v1/access-options/nope')
        .set('authorization', `Bearer ${session.accessToken}`)
        .expect(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });
});
