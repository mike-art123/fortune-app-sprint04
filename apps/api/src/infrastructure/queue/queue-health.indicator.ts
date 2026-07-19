import { Injectable } from '@nestjs/common';
import { RedisHealthIndicator } from '../cache/redis-health.indicator';

/** Queue availability follows its Redis backbone in the foundation phase. */
@Injectable()
export class QueueHealthIndicator {
  constructor(private readonly redisHealth: RedisHealthIndicator) {}

  isHealthy(): Promise<boolean> {
    return this.redisHealth.isHealthy();
  }
}
