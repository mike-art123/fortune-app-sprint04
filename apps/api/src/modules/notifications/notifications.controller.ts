import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { timingSafeEqual } from 'node:crypto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { UpdateNotificationPreferencesDto } from './dto/notification-preferences.dto';
import type { NotificationPreferenceView } from './notification-plan';
import { NotificationsConfig } from './notifications.config';
import { NotificationsService, type SweepResult } from './notifications.service';

/**
 * Notification preferences and the sweep that acts on them (scope §7).
 *
 * The preference routes are the reader's own; the sweep is machine-to-machine
 * and carries a shared secret, because an external scheduler has no session.
 */
@ApiTags('notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly notifications: NotificationsService,
    private readonly config: NotificationsConfig,
  ) {}

  @ApiBearerAuth()
  @Get('preferences')
  preferences(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<NotificationPreferenceView> {
    return this.notifications.preferences(this.required(principal).userId);
  }

  @ApiBearerAuth()
  @Patch('preferences')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  update(
    @Body() dto: UpdateNotificationPreferencesDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<NotificationPreferenceView> {
    return this.notifications.update(this.required(principal).userId, dto);
  }

  /**
   * One pass, driven by an external scheduler. Refuses everything until the
   * secret is configured, so a fresh deployment cannot message anybody.
   */
  @Public()
  @Post('sweep')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 6, ttl: 60_000 } })
  sweep(@Headers('x-sweep-secret') presented: string | undefined): Promise<SweepResult> {
    if (!this.config.isSweepConfigured || !this.matches(presented)) {
      throw new ForbiddenException('sweep is not available');
    }
    return this.notifications.sweep();
  }

  /** Length first, then a constant-time compare of equal-length buffers. */
  private matches(presented: string | undefined): boolean {
    const expected = this.config.sweepSecret;
    if (typeof presented !== 'string' || presented.length !== expected.length) return false;
    return timingSafeEqual(Buffer.from(presented), Buffer.from(expected));
  }

  private required(principal: AuthenticatedPrincipal | undefined): AuthenticatedPrincipal {
    if (!principal) {
      // The global guard guarantees a principal here; this is defense in depth.
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal;
  }
}
