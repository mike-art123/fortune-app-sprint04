import type { Params } from 'nestjs-pino';
import { REDACT_PATHS } from '../../common/utils/redaction.util';

/** Builds pino options (doc 52 §16): JSON in prod, pretty in dev, redaction always. */
export function buildLoggerOptions(env: { level: string; pretty: boolean }): Params {
  return {
    pinoHttp: {
      level: env.level,
      autoLogging: false, // request logs come from LoggingInterceptor with our fields
      redact: { paths: REDACT_PATHS, censor: '[redacted]' },
      transport: env.pretty
        ? { target: 'pino-pretty', options: { singleLine: true, translateTime: 'SYS:HH:MM:ss' } }
        : undefined,
    },
  };
}
