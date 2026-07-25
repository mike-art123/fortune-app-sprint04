import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { CreateMediationDto, ReportFailureDto } from './dto/mediation.dto';
import {
  MediationService,
  type MediationSessionView,
  type MediationStatusView,
} from './mediation.service';

/**
 * Client surface of rewarded-ad mediation. The client asks for a session,
 * reports availability failures, and polls status — it never claims a reward
 * itself; rewards arrive only via the provider server callback.
 */
@ApiTags('ads')
@ApiBearerAuth()
@Controller('ads/mediation')
export class AdsController {
  constructor(private readonly mediation: MediationService) {}

  @Post()
  create(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Body() dto: CreateMediationDto,
  ): Promise<MediationSessionView> {
    return this.mediation.createSession(this.requireUser(principal), dto);
  }

  @Get(':id')
  status(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Param('id') id: string,
  ): Promise<MediationStatusView> {
    return this.mediation.getStatus(this.requireUser(principal), id);
  }

  @Post(':id/failure')
  @HttpCode(HttpStatus.OK)
  reportFailure(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Param('id') id: string,
    @Body() dto: ReportFailureDto,
  ): Promise<MediationSessionView> {
    return this.mediation.reportFailure(this.requireUser(principal), id, dto);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.NO_CONTENT)
  async cancel(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Param('id') id: string,
  ): Promise<void> {
    await this.mediation.cancel(this.requireUser(principal), id);
  }

  private requireUser(principal: AuthenticatedPrincipal | undefined): string {
    if (!principal) {
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal.userId;
  }
}
