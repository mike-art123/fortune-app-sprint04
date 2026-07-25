import { Module } from '@nestjs/common';
import { AdsCallbackController } from './ads-callback.controller';
import { AdsController } from './ads.controller';
import { MediationService } from './mediation.service';

/** Rewarded-ad mediation (multi-provider, backend-owned). */
@Module({
  controllers: [AdsController, AdsCallbackController],
  providers: [MediationService],
  exports: [MediationService],
})
export class AdsModule {}
