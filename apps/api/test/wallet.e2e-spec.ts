import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { ensureTestBotToken, freshTelegramId, loginAs } from './support/telegram-auth';

ensureTestBotToken();

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

/** Requires PostgreSQL + Redis (docker compose up) and a migrated database. */
describe('wallet (e2e) — Sprint 04 identity + debit/refund economy', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const authed = (token: string) => ({ authorization: `Bearer ${token}` });

  it('grants the starter credit as a real ledger row on first sight', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'اول' });

    const res = await request(app.getHttpServer())
      .get('/api/v1/wallet')
      .set(authed(session.accessToken))
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.balance).toBeGreaterThan(0);
    expect(res.body.data.transactions).toHaveLength(1);
    expect(res.body.data.transactions[0].kind).toBe('starter');
    expect(res.body.data.transactions[0].amount).toBe(res.body.data.balance);
  });

  it('is idempotent — a second call returns the same wallet, no second grant', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'دوم' });

    await request(app.getHttpServer())
      .get('/api/v1/wallet')
      .set(authed(session.accessToken))
      .expect(200);
    const res = await request(app.getHttpServer())
      .get('/api/v1/wallet')
      .set(authed(session.accessToken))
      .expect(200);

    expect(res.body.data.transactions).toHaveLength(1);
  });

  it('does not double-grant under concurrent first requests', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'مسابقه' });

    const responses = await Promise.all(
      Array.from({ length: 5 }, () =>
        request(app.getHttpServer()).get('/api/v1/wallet').set(authed(session.accessToken)),
      ),
    );
    for (const res of responses) {
      expect(res.status).toBe(200);
    }

    const after = await request(app.getHttpServer())
      .get('/api/v1/wallet')
      .set(authed(session.accessToken))
      .expect(200);
    expect(after.body.data.transactions).toHaveLength(1);
  });

  it('refuses an unauthenticated caller with the 401 contract', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/wallet').expect(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  describe('reading debit economy', () => {
    it('a paid reading debits the wallet exactly once and records the ledger row', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'خرج' });

      const before = await request(app.getHttpServer())
        .get('/api/v1/wallet')
        .set(authed(session.accessToken))
        .expect(200);
      const startBalance = before.body.data.balance as number;

      await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed(session.accessToken))
        .send({ fortuneId: 'hafez', input: { intention: 'دلم روشن شود' } })
        .expect(201);

      const after = await request(app.getHttpServer())
        .get('/api/v1/wallet')
        .set(authed(session.accessToken))
        .expect(200);

      const debits = after.body.data.transactions.filter(
        (t: { kind: string }) => t.kind === 'debit',
      );
      expect(debits).toHaveLength(1);
      expect(debits[0].amount).toBeLessThan(0);
      expect(after.body.data.balance).toBe(startBalance + debits[0].amount);
    });

    it('the same Idempotency-Key never charges twice and replays the same reading', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'تکرار' });
      const key = `e2e-key-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
      const payload = { fortuneId: 'tarot', input: {} };

      const first = await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed(session.accessToken))
        .set('idempotency-key', key)
        .send(payload)
        .expect(201);

      const second = await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed(session.accessToken))
        .set('idempotency-key', key)
        .send(payload)
        .expect(201);

      expect(second.body.data.id).toBe(first.body.data.id);

      const walletRes = await request(app.getHttpServer())
        .get('/api/v1/wallet')
        .set(authed(session.accessToken))
        .expect(200);
      const debits = walletRes.body.data.transactions.filter(
        (t: { kind: string }) => t.kind === 'debit',
      );
      expect(debits).toHaveLength(1); // one charge, not two
    });

    it('the same Idempotency-Key with different payload is rejected as a conflict', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'تعارض' });
      const key = `e2e-conflict-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;

      await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed(session.accessToken))
        .set('idempotency-key', key)
        .send({ fortuneId: 'hafez', input: {} })
        .expect(201);

      const res = await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed(session.accessToken))
        .set('idempotency-key', key)
        .send({ fortuneId: 'tarot', input: {} })
        .expect(409);
      expect(res.body.error.code).toBe('DUPLICATE_REQUEST');
    });

    it('concurrent identical requests with one key never double-charge', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'همزمان' });
      const key = `e2e-race-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
      const payload = { fortuneId: 'hafez', input: {} };

      const responses = await Promise.all(
        Array.from({ length: 5 }, () =>
          request(app.getHttpServer())
            .post('/api/v1/readings')
            .set(authed(session.accessToken))
            .set('idempotency-key', key)
            .send(payload),
        ),
      );

      // Every response is either the created reading or a controlled conflict —
      // never a silent second charge.
      for (const res of responses) {
        expect([201, 409]).toContain(res.status);
      }
      expect(responses.some((r) => r.status === 201)).toBe(true);

      const walletRes = await request(app.getHttpServer())
        .get('/api/v1/wallet')
        .set(authed(session.accessToken))
        .expect(200);
      const debits = walletRes.body.data.transactions.filter(
        (t: { kind: string }) => t.kind === 'debit',
      );
      expect(debits).toHaveLength(1);
    });

    it('runs the wallet dry and then refuses with INSUFFICIENT_COINS, never negative', async () => {
      const session = await loginAs(app, { id: freshTelegramId(), first_name: 'ته‌کشیده' });

      // Spend until refused (starter balance / cost readings, bounded loop).
      let lastStatus = 201;
      for (let i = 0; i < 40 && lastStatus === 201; i++) {
        const res = await request(app.getHttpServer())
          .post('/api/v1/readings')
          .set(authed(session.accessToken))
          .send({ fortuneId: 'tarot', input: {} });
        lastStatus = res.status;
        if (lastStatus !== 201) {
          expect(res.status).toBe(402);
          expect(res.body.error.code).toBe('INSUFFICIENT_COINS');
        }
      }
      expect(lastStatus).not.toBe(201); // the dry refusal actually happened

      const walletRes = await request(app.getHttpServer())
        .get('/api/v1/wallet')
        .set(authed(session.accessToken))
        .expect(200);
      expect(walletRes.body.data.balance).toBeGreaterThanOrEqual(0);
    });
  });
});
