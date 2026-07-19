import { Module } from '@nestjs/common';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { WalletModule } from '../wallet/wallet.module';
import { AiConfig } from '../../config/ai.config';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { ReadingsController } from './readings.controller';
import { ReadingsRepository } from './readings.repository';
import { ReadingsService } from './readings.service';
import { AiReadingProvider } from './providers/ai-reading.provider';
import { MockReadingProvider } from './providers/mock-reading.provider';
import { READING_PROVIDER, type ReadingProvider } from './providers/reading-provider.interface';

@Module({
  imports: [EntitlementsModule, WalletModule],
  controllers: [ReadingsController],
  providers: [
    ReadingsService,
    ReadingsRepository,
    MockReadingProvider,
    {
      provide: READING_PROVIDER,
      inject: [AiConfig, MockReadingProvider, AppLoggerService],
      /**
       * AI when it is configured, mock otherwise. The decision is made once at
       * boot and logged, so the active provider is never a mystery in prod.
       */
      useFactory: (
        config: AiConfig,
        mock: MockReadingProvider,
        logger: AppLoggerService,
      ): ReadingProvider => {
        if (!config.isConfigured) {
          logger.warn('reading.provider.selected', {
            provider: 'mock',
            reason: 'LLM_BASE_URL or LLM_API_KEY is not set',
          });
          return mock;
        }

        logger.info('reading.provider.selected', {
          provider: 'ai',
          model: config.model,
          timeoutMs: config.timeoutMs,
          maxRetries: config.maxRetries,
        });
        return new AiReadingProvider(config, mock, logger);
      },
    },
  ],
})
export class ReadingsModule {}
