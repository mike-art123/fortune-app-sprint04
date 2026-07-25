import { Controller, Get, HttpCode, HttpStatus, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { MediationService } from './mediation.service';

/**
 * Provider server-to-server reward callbacks — the ONLY path that issues a
 * reward. Public routes (no user JWT: the caller is the ad network), guarded
 * instead by a per-provider shared secret, session/user binding, expiry and
 * DB-level replay protection inside the service.
 *
 * Configure in the provider dashboards (macros differ per network):
 * - AdsGram reward URL:
 *   .../api/v1/ads/callback/adsgram?sid={payload}&uid={userid}&token=<secret>
 * - Monetag S2S postback:
 *   .../api/v1/ads/callback/monetag?sid={var3}&uid={ymid}&reward={request_var}&token=<secret>
 */
@ApiTags('ads')
@Controller('ads/callback')
export class AdsCallbackController {
  constructor(private readonly mediation: MediationService) {}

  @Public()
  @Get('adsgram')
  adsgram(
    @Query('sid') sid?: string,
    @Query('uid') uid?: string,
    @Query('userid') userid?: string,
    @Query('token') token?: string,
    @Query('reward') reward?: string,
  ): Promise<{ ok: true }> {
    return this.mediation.verifyRewardCallback('adsgram', {
      sid,
      uid: uid ?? userid,
      token,
      reward,
    });
  }

  @Public()
  @Get('monetag')
  monetagGet(
    @Query('sid') sid?: string,
    @Query('uid') uid?: string,
    @Query('ymid') ymid?: string,
    @Query('token') token?: string,
    @Query('reward') reward?: string,
  ): Promise<{ ok: true }> {
    return this.mediation.verifyRewardCallback('monetag', {
      sid,
      uid: uid ?? ymid,
      token,
      reward,
    });
  }

  /** Some Monetag postback templates POST instead of GET. */
  @Public()
  @Post('monetag')
  @HttpCode(HttpStatus.OK)
  monetagPost(
    @Query('sid') sid?: string,
    @Query('uid') uid?: string,
    @Query('ymid') ymid?: string,
    @Query('token') token?: string,
    @Query('reward') reward?: string,
  ): Promise<{ ok: true }> {
    return this.mediation.verifyRewardCallback('monetag', {
      sid,
      uid: uid ?? ymid,
      token,
      reward,
    });
  }
}
