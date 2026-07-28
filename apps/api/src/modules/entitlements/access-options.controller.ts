import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { AccessOptionsService, type AccessOptionsView } from './access-options.service';

/**
 * The client calls this AFTER the user taps «گرفتن فال» — never on page open —
 * and renders per accessState: `free` starts immediately; `ad_required` opens
 * the rewarded-ad flow; `unavailable` means no ad can be served right now. All
 * decisions are computed server-side.
 */
@ApiTags('entitlements')
@ApiBearerAuth()
@Controller('access-options')
export class AccessOptionsController {
  constructor(private readonly accessOptions: AccessOptionsService) {}

  @Get(':fortuneId')
  forFortune(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Param('fortuneId') fortuneId: string,
  ): Promise<AccessOptionsView> {
    if (!principal) {
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return this.accessOptions.forFortune(principal.userId, fortuneId);
  }
}
