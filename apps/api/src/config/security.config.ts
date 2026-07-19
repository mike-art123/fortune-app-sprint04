import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SecurityConfig {
  constructor(private readonly config: ConfigService) {}

  get rateLimitTtlSeconds(): number {
    return this.config.getOrThrow<number>('RATE_LIMIT_TTL_SECONDS');
  }
  get rateLimitMax(): number {
    return this.config.getOrThrow<number>('RATE_LIMIT_MAX');
  }
  get jwtIssuer(): string {
    return this.config.getOrThrow<string>('JWT_ISSUER');
  }
  get jwtAudience(): string {
    return this.config.getOrThrow<string>('JWT_AUDIENCE');
  }
}
