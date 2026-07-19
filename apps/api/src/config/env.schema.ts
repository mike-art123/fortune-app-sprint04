import { z } from 'zod';

/**
 * Environment schema (doc 52 §9). Fails fast: invalid production config
 * prevents startup. Test may rely on explicit safe defaults.
 */
export const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
    APP_NAME: z.string().default('fortune-api'),
    APP_HOST: z.string().default('0.0.0.0'),
    APP_PORT: z.coerce.number().int().positive().default(3000),
    API_PREFIX: z.string().default('api'),
    API_VERSION: z.string().default('1'),

    DATABASE_URL: z.string().url(),

    REDIS_HOST: z.string().default('localhost'),
    REDIS_PORT: z.coerce.number().int().positive().default(6379),
    REDIS_USERNAME: z.string().optional(),
    REDIS_PASSWORD: z.string().optional(),
    REDIS_TLS: z.coerce.boolean().default(false),

    QUEUE_PREFIX: z.string().default('fortune'),

    LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
    ENABLE_PRETTY_LOGS: z.coerce.boolean().default(false),

    SWAGGER_ENABLED: z.coerce.boolean().default(true),
    SWAGGER_PATH: z.string().default('docs'),

    CORS_ALLOWED_ORIGINS: z.string().default(''),

    REQUEST_TIMEOUT_MS: z.coerce.number().int().positive().default(30000),
    RATE_LIMIT_TTL_SECONDS: z.coerce.number().int().positive().default(60),
    RATE_LIMIT_MAX: z.coerce.number().int().positive().default(120),

    JWT_ISSUER: z.string().default('fortune-app'),
    JWT_AUDIENCE: z.string().default('fortune-clients'),
    JWT_PUBLIC_KEY: z.string().optional(),
    JWT_PRIVATE_KEY: z.string().optional(),

    TELEGRAM_BOT_TOKEN: z.string().optional(),
    TELEGRAM_BOT_USERNAME: z.string().optional(),

    /** Sprint 04 auth (doc 53). */
    AUTH_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().max(2592000).default(86400),
    TELEGRAM_INITDATA_MAX_AGE_SECONDS: z.coerce.number().int().positive().max(86400).default(3600),

    FEATURE_FLAGS_SOURCE: z.enum(['env', 'database']).default('env'),

    LLM_BASE_URL: z.string().url().optional().or(z.literal('')).default(''),
    LLM_API_KEY: z.string().optional().default(''),
    LLM_MODEL: z.string().default('gpt-4o-mini'),
    LLM_TIMEOUT_MS: z.coerce.number().int().positive().default(20000),
    LLM_MAX_RETRIES: z.coerce.number().int().min(0).max(3).default(1),

    /** Starter credit granted once per wallet, as a real ledger row. */
    WALLET_STARTER_COINS: z.coerce.number().int().min(0).max(1000).default(30),

    /** Coin price of one reading (backend-authoritative economy). */
    WALLET_READING_COST: z.coerce.number().int().min(0).max(1000).default(5),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV === 'production') {
      if (env.SWAGGER_ENABLED && env.CORS_ALLOWED_ORIGINS === '') {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Production requires an explicit CORS allowlist.',
          path: ['CORS_ALLOWED_ORIGINS'],
        });
      }
      // Sprint 04 (doc 53): production must run real auth — no deny-all
      // fallback and no ephemeral keys.
      if (!env.TELEGRAM_BOT_TOKEN) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Production requires TELEGRAM_BOT_TOKEN for Telegram login.',
          path: ['TELEGRAM_BOT_TOKEN'],
        });
      }
      if (!env.JWT_PRIVATE_KEY || !env.JWT_PUBLIC_KEY) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Production requires a persistent JWT keypair.',
          path: ['JWT_PRIVATE_KEY'],
        });
      }
    }
  });

export type Env = z.infer<typeof envSchema>;

export function validateEnv(raw: Record<string, unknown>): Env {
  const parsed = envSchema.safeParse(raw);
  if (!parsed.success) {
    throw new Error(`Invalid environment configuration:\n${parsed.error.toString()}`);
  }
  return parsed.data;
}
