import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaHealthIndicator } from '../../infrastructure/database/prisma-health.indicator';
import { RedisHealthIndicator } from '../../infrastructure/cache/redis-health.indicator';

/** Liveness/readiness (doc 52 §24). No sensitive configuration in responses. */
@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prismaHealth: PrismaHealthIndicator,
    private readonly redisHealth: RedisHealthIndicator,
  ) {}

  @Public()
  @Get('live')
  live(): { status: string } {
    return { status: 'ok' };
  }

  @Public()
  @Get('ready')
  async ready(): Promise<{ status: string; checks: Record<string, string> }> {
    const [database, redis] = await Promise.all([
      this.prismaHealth.isHealthy(),
      this.redisHealth.isHealthy(),
    ]);
    const body = {
      status: database && redis ? 'ok' : 'degraded',
      checks: { database: database ? 'up' : 'down', redis: redis ? 'up' : 'down' },
    };
    if (!database || !redis) {
      throw new ServiceUnavailableException(body);
    }
    return body;
  }
}
