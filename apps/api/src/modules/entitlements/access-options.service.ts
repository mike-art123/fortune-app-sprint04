import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../common/exceptions/domain.exception';
import { AdsConfig } from '../../config/ads.config';
import { MediationService } from '../ads/mediation.service';
import { findFortune } from '../readings/fortune-catalog';
import { FreeDailyService } from './free-daily.service';

/**
 * The access decision for one fortune, computed entirely on the backend.
 * Decision order (spec §15): an unused free-daily allowance starts immediately;
 * otherwise a rewarded ad unlocks the result; if no ad can be served, nothing
 * is available right now. VIP and coins are gone — a rewarded ad is the only
 * unlock, and browsing the app is always free.
 */
export interface AccessOptionsView {
  fortuneId: string;
  isFreeNow: boolean;
  freeUsesRemainingToday: number;
  nextFreeResetAt: string;
  rewardedAdAvailable: boolean;
  rewardedAdsRemainingToday: number;
  accessState: 'free' | 'ad_required' | 'unavailable';
}

@Injectable()
export class AccessOptionsService {
  constructor(
    private readonly freeDaily: FreeDailyService,
    private readonly mediation: MediationService,
    private readonly ads: AdsConfig,
  ) {}

  async forFortune(
    userId: string,
    fortuneId: string,
    now: Date = new Date(),
  ): Promise<AccessOptionsView> {
    if (!findFortune(fortuneId)) {
      throw new DomainException('NOT_FOUND', 'این فال را نمی‌شناسیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    const freeRemaining = await this.freeDaily.freeUsesRemainingToday(userId, fortuneId, now);
    const adsRemaining = await this.mediation.rewardedAdsRemainingToday(userId, now);
    const adConfigured = this.ads.providerOrder.some((p) => this.ads.isConfigured(p));
    const rewardedAdAvailable = adConfigured && adsRemaining > 0;

    let accessState: AccessOptionsView['accessState'] = 'unavailable';
    if (freeRemaining > 0) accessState = 'free';
    else if (rewardedAdAvailable) accessState = 'ad_required';

    return {
      fortuneId,
      isFreeNow: freeRemaining > 0,
      freeUsesRemainingToday: freeRemaining,
      nextFreeResetAt: this.freeDaily.nextFreeResetAt(now).toISOString(),
      rewardedAdAvailable,
      rewardedAdsRemainingToday: adsRemaining,
      accessState,
    };
  }
}
