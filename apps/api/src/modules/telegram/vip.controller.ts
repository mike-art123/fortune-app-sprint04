import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsIn, IsString } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { TelegramPaymentsService, type VipStatusView } from './telegram-payments.service';

export class CreateInvoiceDto {
  @IsString() @IsIn(['monthly', 'quarterly', 'annual']) planId!: string;
}

/**
 * VIP over Telegram Stars: the client reads plans/status and asks for an
 * invoice link to open with Telegram's native payment sheet. Activation only
 * ever happens through the verified webhook — never from the client.
 */
@ApiTags('vip')
@ApiBearerAuth()
@Controller('vip')
export class VipController {
  constructor(private readonly payments: TelegramPaymentsService) {}

  @Get('status')
  status(@CurrentUser() principal: AuthenticatedPrincipal | undefined): Promise<VipStatusView> {
    return this.payments.status(this.requireUser(principal));
  }

  @Post('invoice')
  invoice(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Body() dto: CreateInvoiceDto,
  ): Promise<{ link: string }> {
    return this.payments.createInvoiceLink(this.requireUser(principal), dto.planId);
  }

  private requireUser(principal: AuthenticatedPrincipal | undefined): string {
    if (!principal) {
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal.userId;
  }
}
