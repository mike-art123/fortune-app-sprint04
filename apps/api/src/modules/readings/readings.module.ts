import { Module } from '@nestjs/common';
import { AdsModule } from '../ads/ads.module';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { UsersModule } from '../users/users.module';
import { AiConfig } from '../../config/ai.config';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { ReadingsController } from './readings.controller';
import { ReadingsRepository } from './readings.repository';
import { ReadingsService } from './readings.service';
import { AiReadingProvider } from './providers/ai-reading.provider';
import { MockReadingProvider } from './providers/mock-reading.provider';
import { READING_PROVIDER, type ReadingProvider } from './providers/reading-provider.interface';
import { MonetizationConfig } from '../../config/monetization.config';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { HafezCorpusService } from './hafez/hafez-corpus.service';
import { HafezReadingProvider } from './hafez/hafez-reading.provider';
import { AbjadReadingProvider } from './abjad/abjad-reading.provider';
import { TarotReadingProvider } from './tarot/tarot-reading.provider';
import { LenormandReadingProvider } from './lenormand/lenormand-reading.provider';
import { RuneReadingProvider } from './rune/rune-reading.provider';

@Module({
  imports: [EntitlementsModule, AdsModule, UsersModule],
  controllers: [ReadingsController],
  providers: [
    ReadingsService,
    ReadingsRepository,
    MockReadingProvider,
    HafezCorpusService,
    {
      provide: READING_PROVIDER,
      inject: [
        AiConfig,
        MockReadingProvider,
        AppLoggerService,
        HafezCorpusService,
        FeatureFlagsService,
        MonetizationConfig,
      ],
      /**
       * AI when it is configured, mock otherwise — and the mock is now a
       * development convenience only, never a safety net. `env.schema.ts`
       * refuses to boot production without `LLM_BASE_URL` and `LLM_API_KEY`,
       * so this branch cannot be reached there; the warning is for the local
       * machine, where canned text is fine as long as nobody mistakes it for
       * a reading.
       *
       * The AI provider no longer receives the mock. When generation fails the
       * user gets an honest retry, because thirty-eight fortunes answering with
       * one paragraph is a worse outcome than an error.
       */
      useFactory: (
        config: AiConfig,
        mock: MockReadingProvider,
        logger: AppLoggerService,
        corpus: HafezCorpusService,
        flags: FeatureFlagsService,
        monetization: MonetizationConfig,
      ): ReadingProvider => {
        let inner: ReadingProvider;
        if (!config.isConfigured) {
          logger.warn('reading.provider.selected', {
            provider: 'mock',
            reason: 'LLM_BASE_URL or LLM_API_KEY is not set — readings are canned, not real',
          });
          inner = mock;
        } else {
          logger.info('reading.provider.selected', {
            provider: 'ai',
            model: config.model,
            timeoutMs: config.timeoutMs,
            maxRetries: config.maxRetries,
          });
          inner = new AiReadingProvider(config, logger);
        }

        // The raw engines wrap whichever provider was chosen, one fortune id
        // each. While a flag is off its engine is a pass-through; when it is
        // on, each answers its own fortune from the real source — hafez the
        // Divan, abjad the counted number, tarot and lenormand the drawn card,
        // rune the drawn rune (docs/hafez-dataset-sourcing.md).
        const withHafez = new HafezReadingProvider(
          inner,
          corpus,
          flags,
          config,
          monetization,
          logger,
        );
        const withAbjad = new AbjadReadingProvider(withHafez, flags, config, logger);
        const withTarot = new TarotReadingProvider(withAbjad, flags, config, monetization, logger);
        const withLenormand = new LenormandReadingProvider(
          withTarot,
          flags,
          config,
          monetization,
          logger,
        );
        return new RuneReadingProvider(withLenormand, flags, config, monetization, logger);
      },
    },
  ],
  // The history summary counts readings through this same boundary rather
  // than opening a second door onto the table (scope §6).
  exports: [ReadingsRepository],
})
export class ReadingsModule {}
