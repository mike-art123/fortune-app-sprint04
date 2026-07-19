import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/bootstrap/app-factory';

describe('app pipeline (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = configureApplication(moduleRef.createNestApplication());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('unknown route -> normalized 404 error contract', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/definitely-missing').expect(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('NOT_FOUND');
    expect(res.body.requestId).toBeDefined();
  });

  it('protected route without token -> normalized 401 (Sprint 04)', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/wallet').expect(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('public system info stays open and leaks no secrets', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/system/info').expect(200);
    expect(res.body.data.name).toBeDefined();
    expect(res.body.data).not.toHaveProperty('databaseUrl');
  });

  it('echoes a well-formed incoming request id', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/health/live')
      .set('x-request-id', 'test-req-12345')
      .expect(200);
    expect(res.headers['x-request-id']).toBe('test-req-12345');
  });
});
