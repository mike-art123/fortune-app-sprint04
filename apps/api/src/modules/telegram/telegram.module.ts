import { Module } from '@nestjs/common';
import { TelegramBotConfig } from './telegram-bot.config';
import { TelegramBotService } from './telegram-bot.service';
import { TelegramWebhookController } from './telegram-webhook.controller';

/**
 * Telegram Bot module: receives webhook updates and self-registers the webhook
 * on application startup. Config and logging are global, so nothing extra is
 * imported here.
 */
@Module({
  controllers: [TelegramWebhookController],
  providers: [TelegramBotConfig, TelegramBotService],
})
export class TelegramModule {}
