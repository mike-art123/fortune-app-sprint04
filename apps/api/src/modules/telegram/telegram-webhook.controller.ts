import { Body, Controller, Headers, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { ApiExcludeController } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { TelegramBotService } from './telegram-bot.service';
import type { TelegramUpdate } from './telegram-update.types';

/**
 * Telegram webhook receiver. Public (Telegram sends no bearer token) and
 * excluded from rate limiting. Authenticity is enforced by the secret token
 * Telegram echoes in the `X-Telegram-Bot-Api-Secret-Token` header. Always acks
 * with 200 so Telegram does not enter a retry storm.
 */
@ApiExcludeController()
@Controller('telegram')
export class TelegramWebhookController {
  constructor(
    private readonly bot: TelegramBotService,
    private readonly logger: AppLoggerService,
  ) {}

  @Public()
  @SkipThrottle()
  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  webhook(
    @Headers('x-telegram-bot-api-secret-token') secret: string | undefined,
    @Body() update: TelegramUpdate,
  ): { ok: boolean } {
    if (!this.bot.isValidSecret(secret)) {
      this.logger.warn('telegram.webhook.rejected', {
        reason: 'invalid secret token',
      });
      return { ok: true };
    }
    // Handle out of band; a handler error must never become a Telegram retry.
    void this.bot.handleUpdate(update).catch(() => undefined);
    return { ok: true };
  }
}
