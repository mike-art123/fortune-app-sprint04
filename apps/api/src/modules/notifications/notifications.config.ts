import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Notification sweep configuration (scope §7).
 *
 * The secret is the whole door: while it is empty the sweep route refuses
 * every caller, so a fresh deployment can never message anybody by accident.
 */
@Injectable()
export class NotificationsConfig {
  constructor(private readonly config: ConfigService) {}

  get sweepSecret(): string {
    return this.config.get<string>('NOTIFICATIONS_SWEEP_SECRET') ?? '';
  }

  get sweepBatch(): number {
    return this.config.get<number>('NOTIFICATIONS_SWEEP_BATCH') ?? 200;
  }

  /** No secret, no sweep — not even from inside the network. */
  get isSweepConfigured(): boolean {
    return this.sweepSecret.length > 0;
  }
}
