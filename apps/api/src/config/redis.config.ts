import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class RedisConfig {
  constructor(private readonly config: ConfigService) {}

  get host(): string {
    return this.config.getOrThrow<string>('REDIS_HOST');
  }
  get port(): number {
    return this.config.getOrThrow<number>('REDIS_PORT');
  }
  get username(): string | undefined {
    return this.config.get<string>('REDIS_USERNAME');
  }
  get password(): string | undefined {
    return this.config.get<string>('REDIS_PASSWORD');
  }
  get tls(): boolean {
    return this.config.get<boolean>('REDIS_TLS') ?? false;
  }
}
