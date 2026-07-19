import { HttpStatus, Injectable } from '@nestjs/common';
import { AuthConfig } from '../../config/auth.config';
import { DomainException } from '../../common/exceptions/domain.exception';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { UsersService } from '../users/users.service';
import { verifyTelegramInitData } from './telegram-init-data';
import { TokenService } from './token.service';

export interface LoginResponse {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: {
    id: string;
    telegramId: string;
    displayName: string | null;
    locale: string;
  };
}

/**
 * Telegram login (Sprint 04 / doc 53): initData → verified identity →
 * upserted user (anchor tg:<id>) → signed access token.
 *
 * Privacy: the raw initData and the user's name are never logged; failures
 * log only the mechanical reason.
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly config: AuthConfig,
    private readonly users: UsersService,
    private readonly tokens: TokenService,
    private readonly logger: AppLoggerService,
  ) {}

  async loginWithTelegram(initData: string): Promise<LoginResponse> {
    const botToken = this.config.botToken;
    if (!botToken) {
      // Production cannot reach here (env schema requires the token).
      throw new InfrastructureException('TELEGRAM_BOT_TOKEN is not configured', false);
    }

    const verification = verifyTelegramInitData(initData, botToken, {
      maxAgeSeconds: this.config.initDataMaxAgeSeconds,
    });

    if (!verification.ok) {
      this.logger.warn('auth.telegram.rejected', { reason: verification.reason });
      throw new DomainException('UNAUTHORIZED', 'ورود از تلگرام تأیید نشد؛ دوباره تلاش کن.', {
        status: HttpStatus.UNAUTHORIZED,
        developerMessage: `initData rejected: ${verification.reason}`,
      });
    }

    const user = await this.users.upsertTelegramUser({
      telegramId: verification.telegramId,
      displayName: verification.displayName,
      languageCode: verification.languageCode,
    });

    const signed = this.tokens.sign(user.id, {
      telegramId: user.telegramId,
      roles: ['user'],
    });

    this.logger.info('auth.telegram.login', { userId: user.id });

    return {
      accessToken: signed.accessToken,
      tokenType: 'Bearer',
      expiresIn: signed.expiresInSeconds,
      user: {
        id: user.id,
        telegramId: user.telegramId,
        displayName: user.displayName,
        locale: user.locale,
      },
    };
  }
}
