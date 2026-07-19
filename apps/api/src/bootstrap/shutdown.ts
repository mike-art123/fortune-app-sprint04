import type { INestApplication } from '@nestjs/common';
import { AppLoggerService } from '../infrastructure/logging/app-logger.service';

/**
 * Graceful shutdown (doc 52 §38): SIGTERM/SIGINT close the HTTP server and let
 * Nest lifecycle hooks disconnect Prisma/Redis. A hard timeout guarantees the
 * process never hangs indefinitely.
 */
export function registerShutdown(app: INestApplication, timeoutMs = 15000): void {
  const logger = app.get(AppLoggerService);

  const shutdown = (signal: string): void => {
    logger.info('shutdown_started', { signal });
    const force = setTimeout(() => {
      logger.error('shutdown_forced', { signal });
      process.exit(1);
    }, timeoutMs);
    force.unref();

    void app
      .close()
      .then(() => {
        logger.info('shutdown_complete', { signal });
        process.exit(0);
      })
      .catch(() => process.exit(1));
  };

  process.once('SIGTERM', () => shutdown('SIGTERM'));
  process.once('SIGINT', () => shutdown('SIGINT'));
}
