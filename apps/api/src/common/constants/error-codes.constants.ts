/** Stable machine-readable error codes (docs 33/52 §12). */
export const ERROR_CODES = [
  'VALIDATION_FAILED',
  'UNAUTHORIZED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'RATE_LIMIT',
  'REQUEST_TIMEOUT',
  'INSUFFICIENT_COINS',
  'SUBSCRIPTION_REQUIRED',
  'READING_FAILED',
  'AI_TIMEOUT',
  'AD_VERIFICATION_FAILED',
  'DUPLICATE_REQUEST',
  'INTERNAL',
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];
