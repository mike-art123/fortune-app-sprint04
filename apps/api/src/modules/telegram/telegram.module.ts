import { Module } from '@nestjs/common';
import { AdminStatsService } from './admin-stats.service';
import { TelegramBotConfig } from './telegram-bot.config';
import { TelegramBotService } from './telegram-bot.service';
import { TelegramWebhookController } from './telegram-webhook.controller';

/**
 * Telegram Bot module: webhook receiver (bot /start updates) and webhook
 * self-registration on startup. Config and logging are global, so nothing
 * extra is imported here.
 */
@Module({
  controllers: [TelegramWebhookController],
  providers: [TelegramBotConfig, TelegramBotService, AdminStatsService],
  // Notifications (scope §7) send through this same bot rather than opening a
  // second channel to Telegram.
  exports: [TelegramBotService, TelegramBotConfig],
})
export class TelegramModule {}
