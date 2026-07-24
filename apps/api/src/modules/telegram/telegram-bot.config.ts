import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'node:crypto';
import { AppConfig } from '../../config/app.config';

/**
 * Telegram bot configuration derived from env plus the app's route prefix. The
 * public origin comes from an explicit PUBLIC_BASE_URL or Railway's injected
 * RAILWAY_PUBLIC_DOMAIN, so the webhook can self-register without hardcoding.
 */
@Injectable()
export class TelegramBotConfig {
  constructor(
    private readonly config: ConfigService,
    private readonly app: AppConfig,
  ) {}

  get botToken(): string | null {
    const raw = this.config.get<string>('TELEGRAM_BOT_TOKEN');
    return raw && raw.length > 0 ? raw : null;
  }

  get miniAppUrl(): string {
    return this.config.get<string>('TELEGRAM_MINIAPP_URL') ?? 'https://bakhtnegar.pages.dev';
  }

  /** `/api/v1/telegram/webhook` — global prefix + URI version + route path. */
  get webhookPath(): string {
    return `/${this.app.apiPrefix}/v${this.app.apiVersion}/telegram/webhook`;
  }

  /** Public origin (no trailing slash), or null when it cannot be determined. */
  get publicBaseUrl(): string | null {
    const explicit = this.config.get<string>('PUBLIC_BASE_URL');
    if (explicit && explicit.length > 0) return explicit.replace(/\/+$/, '');
    const domain = this.config.get<string>('RAILWAY_PUBLIC_DOMAIN');
    if (domain && domain.length > 0) return `https://${domain}`;
    return null;
  }

  /** Full public webhook URL, or null when no public origin is available. */
  get webhookUrl(): string | null {
    const base = this.publicBaseUrl;
    return base ? `${base}${this.webhookPath}` : null;
  }

  /**
   * Secret sent to Telegram and echoed back in the
   * `X-Telegram-Bot-Api-Secret-Token` header. Uses an explicit override when
   * set, otherwise a stable value derived from the bot token so no extra env
   * is required.
   */
  get webhookSecret(): string {
    const override = this.config.get<string>('TELEGRAM_WEBHOOK_SECRET');
    if (override && override.length > 0) return override;
    const hash = createHash('sha256').update(this.botToken ?? 'no-token');
    return hash.digest('hex').slice(0, 48);
  }
}
