import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validateEnv } from './env.schema';
import { AppConfig } from './app.config';
import { DatabaseConfig } from './database.config';
import { RedisConfig } from './redis.config';
import { QueueConfig } from './queue.config';
import { SecurityConfig } from './security.config';
import { SwaggerConfig } from './swagger.config';
import { AiConfig } from './ai.config';
import { AuthConfig } from './auth.config';
import { WalletConfig } from './wallet.config';

const providers = [
  AppConfig,
  DatabaseConfig,
  RedisConfig,
  QueueConfig,
  SecurityConfig,
  SwaggerConfig,
  AiConfig,
  AuthConfig,
  WalletConfig,
];

@Global()
@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true, validate: validateEnv })],
  providers,
  exports: providers,
})
export class AppConfigModule {}
