import { HttpStatus, Injectable } from '@nestjs/common';
import { AuthConfig } from '../../config/auth.config';
import { DomainException } from '../../common/exceptions/domain.exception';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { UsersService } from '../users/users.service';
import { verifyTelegramInitData } from './telegram-init-data';
import { TokenService } from './token.service';

/** Dark-launch flag for POST /auth/guest; off until the Play build ships. */
export const GUEST_AUTH_FLAG = 'auth.guest';

export interface LoginResponse {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: {
    id: string;
    /** Null for guest (device-anchored) users. */
    telegramId: string | null;
    displayName: string | null;
    locale: string;
  };
}

/**
 * Login flows (Sprint 04 / doc 53 + Play build): a verified identity →
 * upserted user → signed access token. Telegram anchors on tg:<id> via
 * initData; the Android app anchors on device:<id> via a guest login.
 *
 * Privacy: the raw initData, the device id and the user's name are never
 * logged; failures log only the mechanical reason.
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly config: AuthConfig,
    private readonly users: UsersService,
    private readonly tokens: TokenService,
    private readonly flags: FeatureFlagsService,
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
      telegramId: verification.telegramId,
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

  /**
   * Guest login for the Play build: a stable, app-generated device id is the
   * whole identity. Dark-launched — while the `auth.guest` flag is off the
   * route answers NOT_FOUND, exactly like a feature that does not exist.
   */
  async loginAsGuest(deviceId: string): Promise<LoginResponse> {
    if (!(await this.flags.isEnabled(GUEST_AUTH_FLAG))) {
      throw new DomainException('NOT_FOUND', 'موردی که دنبالش بودی پیدا نشد.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    const user = await this.users.upsertGuestUser({ deviceId });
    const signed = this.tokens.sign(user.id, { roles: ['user'] });

    this.logger.info('auth.guest.login', { userId: user.id });

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
