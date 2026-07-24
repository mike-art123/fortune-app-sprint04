import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { AppConfigModule } from './config/config.module';
import { LoggingModule } from './infrastructure/logging/logging.module';
import { DatabaseModule } from './infrastructure/database/database.module';
import { CacheModule } from './infrastructure/cache/cache.module';
import { QueueModule } from './infrastructure/queue/queue.module';
import { EventsModule } from './infrastructure/events/events.module';
import { IdempotencyModule } from './infrastructure/idempotency/idempotency.module';
import { FeatureFlagsModule } from './infrastructure/feature-flags/feature-flags.module';
import { ObservabilityModule } from './infrastructure/observability/observability.module';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';
import { AuthGuard } from './common/guards/auth.guard';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { EntitlementsModule } from './modules/entitlements/entitlements.module';
import { ReadingsModule } from './modules/readings/readings.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { HealthModule } from './modules/health/health.module';
import { SystemModule } from './modules/system/system.module';
import { TelegramModule } from './modules/telegram/telegram.module';

@Module({
  imports: [
    AppConfigModule,
    LoggingModule,
    DatabaseModule,
    CacheModule,
    QueueModule,
    EventsModule,
    IdempotencyModule,
    FeatureFlagsModule,
    ObservabilityModule,
    // Baseline rate limit (doc 52 §27); Redis-backed store hook comes with the
    // first real feature limits. Route overrides via @Throttle().
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        throttlers: [
          {
            ttl: (config.get<number>('RATE_LIMIT_TTL_SECONDS') ?? 60) * 1000,
            limit: config.get<number>('RATE_LIMIT_MAX') ?? 120,
          },
        ],
      }),
    }),
    AuthModule,
    UsersModule,
    EntitlementsModule,
    ReadingsModule,
    WalletModule,
    HealthModule,
    SystemModule,
    TelegramModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
