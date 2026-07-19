import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class DatabaseConfig {
  constructor(private readonly config: ConfigService) {}

  get url(): string {
    return this.config.getOrThrow<string>('DATABASE_URL');
  }
}
