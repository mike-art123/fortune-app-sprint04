import { Module } from '@nestjs/common';
import { TelegramModule } from '../telegram/telegram.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsConfig } from './notifications.config';
import { NotificationsService } from './notifications.service';

/**
 * Smart notifications (scope §7). Delivery rides the existing Telegram bot —
 * no second channel to Telegram is opened here.
 */
@Module({
  imports: [TelegramModule],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsConfig],
})
export class NotificationsModule {}
