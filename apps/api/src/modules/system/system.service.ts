import { Injectable } from '@nestjs/common';
import { AppConfig } from '../../config/app.config';
import { nowIso } from '../../common/utils/date.util';

/** Safe system info (doc 52 §50) — no hosts, secrets, or internal names. */
@Injectable()
export class SystemService {
  constructor(private readonly appConfig: AppConfig) {}

  info(): Record<string, string> {
    return {
      name: this.appConfig.appName,
      apiVersion: `v${this.appConfig.apiVersion}`,
      environment: this.appConfig.nodeEnv,
      serverTime: nowIso(),
    };
  }
}
