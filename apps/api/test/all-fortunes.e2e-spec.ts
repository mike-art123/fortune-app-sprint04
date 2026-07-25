import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { ensureTestBotToken, freshTelegramId, loginAs } from './support/telegram-auth';

ensureTestBotToken();

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';
import { FORTUNE_CATALOG } from '../src/modules/readings/fortune-catalog';

/**
 * Final pre-push audit: EVERY catalog fortune must produce a real reading end
 * to end (controller → DTO → service → access decision → provider → persist →
 * envelope), land in history, and reflect the user's input. No fortune may be
 * "present in the catalog but broken in practice".
 *
 * Requires PostgreSQL + Redis (docker compose up) and a migrated database.
 */
describe('all fortunes (e2e) — every catalog entry yields a real reading', () => {
  let app: INestApplication;
  let auth: { authorization: string };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'ممیز' });
    auth = { authorization: `Bearer ${session.accessToken}` };
  }, 30000);

  afterAll(async () => {
    await app.close();
  });

  function inputFor(kind: string): Record<string, string> {
    if (kind === 'longText') {
      return { narration: 'خواب دیدم در باغی روشن قدم می‌زنم و آبی زلال جاری بود' };
    }
    if (kind === 'twoNames') {
      return { selfName: 'سارا', otherName: 'امیر' };
    }
    return { intention: 'دلم روشن شود' };
  }

  it(
    'creates a reading for every single catalog fortune and saves history',
    async () => {
      const created: string[] = [];

      for (const fortune of FORTUNE_CATALOG) {
        const res = await request(app.getHttpServer())
          .post('/api/v1/readings')
          .set(auth)
          .send({ fortuneId: fortune.id, input: inputFor(fortune.inputKind) });

        expect({ id: fortune.id, status: res.status }).toEqual({ id: fortune.id, status: 201 });
        const data = res.body.data as {
          id: string;
          fortune: string;
          title: string;
          reading: string;
        };
        expect(data.fortune).toBe(fortune.id);
        expect(data.title.length).toBeGreaterThan(0);
        expect(data.reading.length).toBeGreaterThan(20);
        created.push(data.id);
      }

      expect(created).toHaveLength(FORTUNE_CATALOG.length);

      // Every one of them is in the user's history (newest-first pages).
      const seen = new Set<string>();
      let cursor: string | null = null;
      for (let page = 0; page < 6; page++) {
        const url = cursor
          ? `/api/v1/readings?limit=20&cursor=${encodeURIComponent(cursor)}`
          : '/api/v1/readings?limit=20';
        const list = await request(app.getHttpServer()).get(url).set(auth).expect(200);
        for (const item of list.body.data.items as { id: string }[]) seen.add(item.id);
        cursor = list.body.data.nextCursor as string | null;
        if (!cursor) break;
      }
      for (const id of created) expect(seen.has(id)).toBe(true);

      // Ownership: a created reading is retrievable by its owner.
      const one = created[0] as string;
      const byId = await request(app.getHttpServer())
        .get(`/api/v1/readings/${one}`)
        .set(auth)
        .expect(200);
      expect(byId.body.data.id).toBe(one);
    },
    120000,
  );

  it('the user input truly shapes the result (two-names carries the names)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'marriage', input: { selfName: 'مینا', otherName: 'کاوه' } })
      .expect(201);

    expect(res.body.data.reading).toContain('مینا');
    expect(res.body.data.reading).toContain('کاوه');
  });

  it('an offered intention and a silent one produce different openings', async () => {
    const withIntent = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'candle', input: { intention: 'آرامشِ خانه' } })
      .expect(201);
    const silent = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'candle', input: {} })
      .expect(201);

    expect(withIntent.body.data.reading).not.toBe(silent.body.data.reading);
  });

  it('server-side offering validation refuses incomplete required inputs', async () => {
    const dream = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'dream', input: { narration: 'خواب' } })
      .expect(400);
    expect(dream.body.error.code).toBe('VALIDATION_FAILED');

    const love = await request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId: 'reconcile', input: { selfName: 'سارا' } })
      .expect(400);
    expect(love.body.error.code).toBe('VALIDATION_FAILED');
  });
});
