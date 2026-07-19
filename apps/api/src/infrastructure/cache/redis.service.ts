import { Injectable, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { RedisConfig } from '../../config/redis.config';
import { AppConfig } from '../../config/app.config';

/**
 * Redis connection owner (doc 52 §20). Keys are always namespaced
 * `fortune:{env}:{...}`. Redis is never the source of truth for balances.
 */
@Injectable()
export class RedisService implements OnModuleDestroy {
  readonly client: Redis;
  private readonly namespace: string;

  constructor(redisConfig: RedisConfig, appConfig: AppConfig) {
    this.namespace = `fortune:${appConfig.nodeEnv}`;
    this.client = new Redis({
      host: redisConfig.host,
      port: redisConfig.port,
      username: redisConfig.username,
      password: redisConfig.password,
      tls: redisConfig.tls ? {} : undefined,
      lazyConnect: true,
      maxRetriesPerRequest: 2,
      connectTimeout: 5000,
    });
  }

  key(...parts: string[]): string {
    return [this.namespace, ...parts].join(':');
  }

  async getJson<T>(key: string): Promise<T | null> {
    const raw = await this.client.get(key);
    if (raw === null) return null;
    try {
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async setJson(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    const raw = JSON.stringify(value);
    if (ttlSeconds && ttlSeconds > 0) {
      await this.client.set(key, raw, 'EX', ttlSeconds);
    } else {
      await this.client.set(key, raw);
    }
  }

  async ping(): Promise<boolean> {
    if (this.client.status !== 'ready') await this.client.connect();
    return (await this.client.ping()) === 'PONG';
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.quit().catch(() => this.client.disconnect());
  }
}
