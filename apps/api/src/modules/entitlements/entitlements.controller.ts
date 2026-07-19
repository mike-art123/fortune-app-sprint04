import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { EntitlementsService, type Entitlement } from './entitlements.service';

/**
 * Read-only entitlement surface (Sprint 04 / doc 53): the client asks what a
 * reading costs and whether a subscription covers it. Pricing decisions stay
 * server-side; the client only displays.
 */
@ApiTags('entitlements')
@ApiBearerAuth()
@Controller('entitlements')
export class EntitlementsController {
  constructor(private readonly entitlements: EntitlementsService) {}

  @Get('me')
  me(@CurrentUser() principal: AuthenticatedPrincipal | undefined): Promise<Entitlement> {
    if (!principal) {
      // The global guard guarantees a principal here; this is defense in depth.
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return this.entitlements.assessReading(principal.userId);
  }
}
