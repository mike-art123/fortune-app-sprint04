import { Injectable, type OnApplicationBootstrap } from '@nestjs/common';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { TelegramBotConfig } from './telegram-bot.config';
import type { TelegramUpdate } from './telegram-update.types';

interface TelegramApiResponse {
  ok: boolean;
  description?: string;
  result?: unknown;
}

const TELEGRAM_API = 'https://api.telegram.org';
const REQUEST_TIMEOUT_MS = 10_000;

/**
 * Telegram Bot integration: self-registers the webhook on startup and answers
 * `/start` with a WebApp button that opens the Mini App. Outbound calls are
 * time-bounded and every outcome is logged; a Telegram failure never throws
 * into the request path.
 */
@Injectable()
export class TelegramBotService implements OnApplicationBootstrap {
  constructor(
    private readonly config: TelegramBotConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (!this.config.botToken) {
      this.logger.warn('telegram.bot.disabled', {
        reason: 'TELEGRAM_BOT_TOKEN is not set',
      });
      return;
    }

    const url = this.config.webhookUrl;
    if (!url) {
      this.logger.warn('telegram.webhook.skipped', {
        reason: 'no PUBLIC_BASE_URL or RAILWAY_PUBLIC_DOMAIN to build the webhook URL',
      });
      return;
    }

    try {
      const res = await this.call('setWebhook', {
        url,
        secret_token: this.config.webhookSecret,
        allowed_updates: ['message'],
      });
      if (res.ok) {
        this.logger.info('telegram.webhook.registered', { url });
      } else {
        this.logger.error('telegram.webhook.failed', {
          url,
          description: res.description ?? 'unknown',
        });
      }
    } catch (error) {
      this.logger.error('telegram.webhook.error', {
        url,
        error: error instanceof Error ? error.message : 'unknown',
      });
    }
  }

  /** Length-then-value comparison of the secret header Telegram echoes back. */
  isValidSecret(header: string | undefined): boolean {
    const expected = this.config.webhookSecret;
    return typeof header === 'string' && header.length === expected.length && header === expected;
  }

  async handleUpdate(update: TelegramUpdate): Promise<void> {
    const message = update.message;
    const text = message?.text?.trim() ?? '';
    const chatId = message?.chat?.id;
    if (chatId == null || !text.startsWith('/start')) return;
    await this.sendStart(chatId);
  }

  private async sendStart(chatId: number): Promise<void> {
    try {
      const res = await this.call('sendMessage', {
        chat_id: chatId,
        text: 'به بخت‌نگار خوش آمدی ✨\nبرای گرفتن فال، دکمهٔ زیر را بزن.',
        reply_markup: {
          inline_keyboard: [
            [
              {
                text: '🔮 باز کردن بخت‌نگار',
                web_app: { url: this.config.miniAppUrl },
              },
            ],
          ],
        },
      });
      if (res.ok) {
        this.logger.info('telegram.start.sent', { chatId });
      } else {
        this.logger.warn('telegram.start.failed', {
          chatId,
          description: res.description ?? 'unknown',
        });
      }
    } catch (error) {
      this.logger.error('telegram.start.error', {
        chatId,
        error: error instanceof Error ? error.message : 'unknown',
      });
    }
  }

  private async call(method: string, body: unknown): Promise<TelegramApiResponse> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetch(`${TELEGRAM_API}/bot${this.config.botToken}/${method}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      return (await response.json()) as TelegramApiResponse;
    } finally {
      clearTimeout(timeout);
    }
  }
}
