import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Typed auth configuration (Sprint 04 / doc 53). Production validity is
 * enforced by the env schema (bot token + JWT keypair required); these getters
 * only read what validation already admitted.
 */
@Injectable()
export class AuthConfig {
  constructor(private readonly config: ConfigService) {}

  get botToken(): string | null {
    const raw = this.config.get<string>('TELEGRAM_BOT_TOKEN');
    return raw && raw.length > 0 ? raw : null;
  }

  get isTelegramConfigured(): boolean {
    return this.botToken !== null;
  }

  /** PEM private key; env files store newlines as literal \n. */
  get jwtPrivateKey(): string | null {
    return this.readPem('JWT_PRIVATE_KEY');
  }

  get jwtPublicKey(): string | null {
    return this.readPem('JWT_PUBLIC_KEY');
  }

  get tokenTtlSeconds(): number {
    return this.config.get<number>('AUTH_TOKEN_TTL_SECONDS') ?? 86400;
  }

  get initDataMaxAgeSeconds(): number {
    return this.config.get<number>('TELEGRAM_INITDATA_MAX_AGE_SECONDS') ?? 3600;
  }

  private readPem(key: string): string | null {
    const raw = this.config.get<string>(key);
    if (!raw || raw.length === 0) return null;
    return raw.replace(/\\n/g, '\n');
  }
}
