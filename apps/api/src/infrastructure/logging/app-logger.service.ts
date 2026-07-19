import { Injectable } from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';
import { redact } from '../../common/utils/redaction.util';

/**
 * Application logging facade (doc 52 §16). Feature code depends on this, not
 * on pino directly. String payloads pass through redaction defensively.
 */
@Injectable()
export class AppLoggerService {
  constructor(private readonly logger: PinoLogger) {
    this.logger.setContext('app');
  }

  debug(message: string, fields?: Record<string, unknown>): void {
    this.logger.debug(fields ?? {}, redact(message));
  }
  info(message: string, fields?: Record<string, unknown>): void {
    this.logger.info(fields ?? {}, redact(message));
  }
  warn(message: string, fields?: Record<string, unknown>): void {
    this.logger.warn(fields ?? {}, redact(message));
  }
  error(message: string, fields?: Record<string, unknown>): void {
    this.logger.error(fields ?? {}, redact(message));
  }
}
