import { Module } from '@nestjs/common';
import { AdsModule } from '../ads/ads.module';
import { AccessOptionsController } from './access-options.controller';
import { AccessOptionsService } from './access-options.service';
import { EntitlementsController } from './entitlements.controller';
import { EntitlementsService } from './entitlements.service';
import { FreeDailyService } from './free-daily.service';

/** Access authority: VIP, free-daily allowance and the access-options view. */
@Module({
  imports: [AdsModule],
  controllers: [EntitlementsController, AccessOptionsController],
  providers: [EntitlementsService, FreeDailyService, AccessOptionsService],
  exports: [EntitlementsService, FreeDailyService],
})
export class EntitlementsModule {}
