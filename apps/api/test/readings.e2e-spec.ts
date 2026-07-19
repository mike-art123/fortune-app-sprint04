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

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

/** Requires PostgreSQL + Redis (docker compose up) and a migrated database. */
describe('readings (e2e) — Sprint 04 authenticated flow', () => {
  let app: INestApplication;
  let session: LoginSession;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
    session = await loginAs(app, { id: freshTelegramId(), first_name: 'خواننده' });
  });

  afterAll(async () => {
    await app.close();
  });

  const authed = { get authorization() { return `Bearer ${session.accessToken}`; } };

  it('POST /api/v1/readings creates a hafez reading for the caller', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .send({ fortuneId: 'hafez', input: { intention: 'دلم روشن شود' } })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data.fortune).toBe('hafez');
    expect(res.body.data.title.length).toBeGreaterThan(0);
    expect(res.body.data.reading.length).toBeGreaterThan(0);
    expect(res.body.data.createdAt).toBeDefined();
  });

  it('refuses an unauthenticated create with the 401 contract', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .send({ fortuneId: 'hafez', input: {} })
      .expect(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('rejects an unknown fortune with the error contract', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .send({ fortuneId: 'unknown', input: {} })
      .expect(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('rejects unknown payload fields (whitelist)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .send({ fortuneId: 'hafez', input: {}, hack: true })
      .expect(400);
    expect(res.body.error.code).toBe('VALIDATION_FAILED');
  });

  it('rejects love with one name at the server boundary', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(authed)
      .send({ fortuneId: 'love', input: { selfName: 'سارا' } })
      .expect(400);
    expect(res.body.error.code).toBe('VALIDATION_FAILED');
  });

  describe('history — scoped to the authenticated user', () => {
    it('create → list → get round-trip, newest first', async () => {
      const created = await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed)
        .send({ fortuneId: 'hafez', input: { intention: 'برای تاریخچه' } })
        .expect(201);
      const id = created.body.data.id as string;

      const list = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set(authed)
        .expect(200);
      expect(list.body.success).toBe(true);
      expect(list.body.data.items[0].id).toBe(id); // newest first

      const detail = await request(app.getHttpServer())
        .get(`/api/v1/readings/${id}`)
        .set(authed)
        .expect(200);
      expect(detail.body.data.id).toBe(id);
      expect(detail.body.data.title).toBe(created.body.data.title);
    });

    it("another user's history is empty and their detail view is closed", async () => {
      const mine = await request(app.getHttpServer())
        .post('/api/v1/readings')
        .set(authed)
        .send({ fortuneId: 'tarot', input: {} })
        .expect(201);
      const myReadingId = mine.body.data.id as string;

      const stranger = await loginAs(app, { id: freshTelegramId(), first_name: 'غریبه' });
      const strangerAuth = { authorization: `Bearer ${stranger.accessToken}` };

      const list = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set(strangerAuth)
        .expect(200);
      expect(
        list.body.data.items.some((i: { id: string }) => i.id === myReadingId),
      ).toBe(false);

      const detail = await request(app.getHttpServer())
        .get(`/api/v1/readings/${myReadingId}`)
        .set(strangerAuth)
        .expect(404);
      expect(detail.body.error.code).toBe('NOT_FOUND');
    });

    it('paginates with an opaque cursor and terminates', async () => {
      for (let i = 0; i < 3; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/readings')
          .set(authed)
          .send({ fortuneId: 'tarot', input: {} })
          .expect(201);
      }

      const first = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set(authed)
        .query({ limit: 2 })
        .expect(200);
      expect(first.body.data.items).toHaveLength(2);
      expect(typeof first.body.data.nextCursor).toBe('string');

      const seen = new Set(first.body.data.items.map((i: { id: string }) => i.id));
      let cursor: string | null = first.body.data.nextCursor;
      let hops = 0;
      while (cursor && hops < 10) {
        const page = await request(app.getHttpServer())
          .get('/api/v1/readings')
          .set(authed)
          .query({ limit: 2, cursor })
          .expect(200);
        for (const item of page.body.data.items) {
          expect(seen.has(item.id)).toBe(false); // no duplicates across pages
          seen.add(item.id);
        }
        cursor = page.body.data.nextCursor;
        hops++;
      }
      expect(cursor).toBeNull();
    });

    it('treats a corrupt cursor as page one', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set(authed)
        .query({ cursor: '💥💥💥' })
        .expect(200);
      expect(Array.isArray(res.body.data.items)).toBe(true);
    });

    it('rejects an out-of-range limit at the boundary', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set(authed)
        .query({ limit: 500 })
        .expect(400);
      expect(res.body.error.code).toBe('VALIDATION_FAILED');
    });
  });
});
