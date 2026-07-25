import { Module } from '@nestjs/common';
import { TelegramBotConfig } from './telegram-bot.config';
import { TelegramBotService } from './telegram-bot.service';
import { TelegramPaymentsService } from './telegram-payments.service';
import { TelegramWebhookController } from './telegram-webhook.controller';
import { VipController } from './vip.controller';

/**
 * Telegram Bot module: webhook receiver (start + Stars payment updates),
 * webhook self-registration on startup, and the VIP invoice/status surface.
 * Config and logging are global, so nothing extra is imported here.
 */
@Module({
  controllers: [TelegramWebhookController, VipController],
  providers: [TelegramBotConfig, TelegramBotService, TelegramPaymentsService],
})
export class TelegramModule {}
