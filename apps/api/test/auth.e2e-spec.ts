import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import {
  buildInitData,
  ensureTestBotToken,
  freshTelegramId,
  loginAs,
} from './support/telegram-auth';

ensureTestBotToken();

// Imported after the env is prepared.
import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';
import { PrismaService } from '../src/infrastructure/database/prisma.service';

/** Requires PostgreSQL + Redis (docker compose up) and a migrated database. */
describe('auth (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('exchanges valid initData for a bearer token and the tg:<id> user', async () => {
    const tgId = freshTelegramId();
    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/telegram')
      .send({ initData: buildInitData({ id: tgId, first_name: 'سارا', language_code: 'fa' }) })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.tokenType).toBe('Bearer');
    expect(res.body.data.expiresIn).toBeGreaterThan(0);
    expect(res.body.data.user.telegramId).toBe(String(tgId));
    expect(res.body.data.accessToken.split('.')).toHaveLength(3);
  });

  it('is stable: the same Telegram account maps to the same user on re-login', async () => {
    const tgId = freshTelegramId();
    const first = await loginAs(app, { id: tgId, first_name: 'مهتاب' });
    const second = await loginAs(app, { id: tgId, first_name: 'مهتاب' });

    expect(second.userId).toBe(first.userId);
  });

  it('rejects tampered initData with the 401 error contract', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/telegram')
      .send({ initData: buildInitData({ id: freshTelegramId() }, { tamper: true }) })
      .expect(401);

    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('rejects initData signed by a different bot', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/telegram')
      .send({
        initData: buildInitData({ id: freshTelegramId() }, { botToken: '1111:not-our-bot' }),
      })
      .expect(401);
  });

  it('rejects stale initData', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/telegram')
      .send({
        initData: buildInitData(
          { id: freshTelegramId() },
          { authDate: Math.floor(Date.now() / 1000) - 86_400 * 2 },
        ),
      })
      .expect(401);
  });

  it('rejects a missing/empty body at the validation boundary', async () => {
    await request(app.getHttpServer()).post('/api/v1/auth/telegram').send({}).expect(400);
  });

  it('protected routes 401 without a token and with a forged token', async () => {
    for (const path of ['/api/v1/wallet', '/api/v1/readings']) {
      const bare = await request(app.getHttpServer()).get(path).expect(401);
      expect(bare.body.error.code).toBe('UNAUTHORIZED');

      await request(app.getHttpServer())
        .get(path)
        .set('authorization', 'Bearer not.a.token')
        .expect(401);
    }
  });

  it('a fresh login token opens protected routes', async () => {
    const session = await loginAs(app, { id: freshTelegramId(), first_name: 'آزمون' });

    const res = await request(app.getHttpServer())
      .get('/api/v1/wallet')
      .set('authorization', `Bearer ${session.accessToken}`)
      .expect(200);
    expect(res.body.success).toBe(true);
  });

  describe('guest login (Play build)', () => {
    const deviceId = `e2e-device-${Date.now()}-4f9a1b2c3d`;

    beforeAll(async () => {
      // Turned on for this suite exactly the way production turns it on: a
      // feature_flags row (the code default is off — dark launch).
      await app.get(PrismaService).featureFlag.upsert({
        where: { key: 'auth.guest' },
        create: { key: 'auth.guest', enabled: true },
        update: { enabled: true },
      });
    });

    it('exchanges a device id for a bearer token and a guest user', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/guest')
        .send({ deviceId })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.tokenType).toBe('Bearer');
      expect(res.body.data.user.telegramId).toBeNull();
      expect(res.body.data.accessToken.split('.')).toHaveLength(3);
    });

    it('is stable: the same device maps to the same user on re-login', async () => {
      const first = await request(app.getHttpServer())
        .post('/api/v1/auth/guest')
        .send({ deviceId })
        .expect(200);
      const second = await request(app.getHttpServer())
        .post('/api/v1/auth/guest')
        .send({ deviceId })
        .expect(200);

      expect(second.body.data.user.id).toBe(first.body.data.user.id);
    });

    it('a guest token opens protected routes', async () => {
      const login = await request(app.getHttpServer())
        .post('/api/v1/auth/guest')
        .send({ deviceId })
        .expect(200);

      const res = await request(app.getHttpServer())
        .get('/api/v1/readings')
        .set('authorization', `Bearer ${login.body.data.accessToken}`)
        .expect(200);
      expect(res.body.success).toBe(true);
    });

    it('rejects a malformed device id at the validation boundary', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/auth/guest')
        .send({ deviceId: 'short!' })
        .expect(400);
      await request(app.getHttpServer()).post('/api/v1/auth/guest').send({}).expect(400);
    });
  });
});
