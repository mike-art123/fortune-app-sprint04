import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Typed application config (doc 52 §9.3). No raw process.env in app code. */
@Injectable()
export class AppConfig {
  constructor(private readonly config: ConfigService) {}

  get nodeEnv(): string {
    return this.config.getOrThrow<string>('NODE_ENV');
  }
  get isProduction(): boolean {
    return this.nodeEnv === 'production';
  }
  get isTest(): boolean {
    return this.nodeEnv === 'test';
  }
  get appName(): string {
    return this.config.getOrThrow<string>('APP_NAME');
  }
  get host(): string {
    return this.config.getOrThrow<string>('APP_HOST');
  }
  get port(): number {
    return this.config.getOrThrow<number>('APP_PORT');
  }
  get apiPrefix(): string {
    return this.config.getOrThrow<string>('API_PREFIX');
  }
  get apiVersion(): string {
    return this.config.getOrThrow<string>('API_VERSION');
  }
  get requestTimeoutMs(): number {
    return this.config.getOrThrow<number>('REQUEST_TIMEOUT_MS');
  }
  get corsAllowedOrigins(): string[] {
    const raw = this.config.get<string>('CORS_ALLOWED_ORIGINS') ?? '';
    return raw
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }
}
