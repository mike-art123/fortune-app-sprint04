import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SwaggerConfig {
  constructor(private readonly config: ConfigService) {}

  get enabled(): boolean {
    return this.config.get<boolean>('SWAGGER_ENABLED') ?? true;
  }
  get path(): string {
    return this.config.get<string>('SWAGGER_PATH') ?? 'docs';
  }
}
