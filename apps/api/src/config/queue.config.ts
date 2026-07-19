import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class QueueConfig {
  constructor(private readonly config: ConfigService) {}

  get prefix(): string {
    return this.config.getOrThrow<string>('QUEUE_PREFIX');
  }
}
