import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { ensureTestBotToken, freshTelegramId, loginAs } from './support/telegram-auth';

ensureTestBotToken();

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

/** Requires PostgreSQL + Redis (docker compose up) and a migrated database. */
describe('readings deletion (e2e) — permanent and scoped to the owner', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  async function freshOwner(name: string): Promise<{ authorization: string }> {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: name });
    return { authorization: `Bearer ${session.accessToken}` };
  }

  function createReading(auth: { authorization: string }, fortuneId: string) {
    return request(app.getHttpServer())
      .post('/api/v1/readings')
      .set(auth)
      .send({ fortuneId, input: {} })
      .expect(201);
  }

  it("DELETE /api/v1/readings/:id removes one of the caller's readings", async () => {
    const owner = await freshOwner('صاحب');
    const first = await createReading(owner, 'tarot');
    await createReading(owner, 'yesno');

    const removed = await request(app.getHttpServer())
      .delete(`/api/v1/readings/${first.body.data.id}`)
      .set(owner)
      .expect(200);
    expect(removed.body.data.deleted).toBe(1);

    const list = await request(app.getHttpServer()).get('/api/v1/readings').set(owner).expect(200);
    const stillThere = list.body.data.items.some(
      (i: { id: string }) => i.id === first.body.data.id,
    );
    expect(stillThere).toBe(false);
    expect(list.body.data.items).toHaveLength(1);
  });

  it("DELETE /api/v1/readings clears the caller's whole history", async () => {
    const owner = await freshOwner('پاک‌کننده');
    await createReading(owner, 'tarot');
    await createReading(owner, 'yesno');

    const cleared = await request(app.getHttpServer())
      .delete('/api/v1/readings')
      .set(owner)
      .expect(200);
    expect(cleared.body.data.deleted).toBe(2);

    const list = await request(app.getHttpServer()).get('/api/v1/readings').set(owner).expect(200);
    expect(list.body.data.items).toHaveLength(0);
  });

  it("cannot touch another user's reading, and says zero", async () => {
    const owner = await freshOwner('مالک');
    const created = await createReading(owner, 'tarot');
    const intruder = await freshOwner('مزاحم');

    const res = await request(app.getHttpServer())
      .delete(`/api/v1/readings/${created.body.data.id}`)
      .set(intruder)
      .expect(200);
    expect(res.body.data.deleted).toBe(0);

    const list = await request(app.getHttpServer()).get('/api/v1/readings').set(owner).expect(200);
    const stillOwned = list.body.data.items.some(
      (i: { id: string }) => i.id === created.body.data.id,
    );
    expect(stillOwned).toBe(true);
  });
});
