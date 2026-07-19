import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { buildLoggerOptions } from './logger.factory';
import { AppLoggerService } from './app-logger.service';

@Global()
@Module({
  imports: [
    LoggerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        buildLoggerOptions({
          level: config.get<string>('LOG_LEVEL') ?? 'info',
          pretty: config.get<boolean>('ENABLE_PRETTY_LOGS') ?? false,
        }),
    }),
  ],
  providers: [AppLoggerService],
  exports: [AppLoggerService],
})
export class LoggingModule {}
