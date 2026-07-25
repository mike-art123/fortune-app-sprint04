import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../common/exceptions/domain.exception';
import { AdsConfig } from '../../config/ads.config';
import { MediationService } from '../ads/mediation.service';
import { findFortune } from '../readings/fortune-catalog';
import { EntitlementsService } from './entitlements.service';
import { FreeDailyService } from './free-daily.service';

/**
 * The access decision for one fortune, computed entirely on the backend.
 * Decision order (spec): VIP -> unused free daily -> the two-choice sheet
 * (rewarded ad / VIP). No coin fields exist anywhere in this contract.
 */
export interface AccessOptionsView {
  fortuneId: string;
  isVip: boolean;
  isFreeNow: boolean;
  freeUsesRemainingToday: number;
  nextFreeResetAt: string;
  rewardedAdAvailable: boolean;
  rewardedAdsRemainingToday: number;
  vipAvailable: boolean;
  vipIncluded: boolean;
  accessState: 'vip' | 'free' | 'choice' | 'vip_only';
}

@Injectable()
export class AccessOptionsService {
  constructor(
    private readonly entitlements: EntitlementsService,
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

    const isVip = await this.entitlements.hasActiveVip(userId, now);
    const freeRemaining = await this.freeDaily.freeUsesRemainingToday(userId, fortuneId, now);
    const adsRemaining = await this.mediation.rewardedAdsRemainingToday(userId, now);
    const adConfigured = this.ads.providerOrder.some((p) => this.ads.isConfigured(p));
    const rewardedAdAvailable = adConfigured && adsRemaining > 0;

    let accessState: AccessOptionsView['accessState'] = 'vip_only';
    if (isVip) accessState = 'vip';
    else if (freeRemaining > 0) accessState = 'free';
    else if (rewardedAdAvailable) accessState = 'choice';

    return {
      fortuneId,
      isVip,
      isFreeNow: !isVip && freeRemaining > 0,
      freeUsesRemainingToday: freeRemaining,
      nextFreeResetAt: this.freeDaily.nextFreeResetAt(now).toISOString(),
      rewardedAdAvailable,
      rewardedAdsRemainingToday: adsRemaining,
      vipAvailable: true,
      vipIncluded: true,
      accessState,
    };
  }
}
