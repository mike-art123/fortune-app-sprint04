/**
 * Log redaction (doc 52 §16). Central list of sensitive patterns — auth tokens,
 * Telegram init data, secret request headers (sweep + telegram webhook), and
 * personal ritual input keys.
 */
const PATTERNS: ReadonlyArray<[RegExp, string]> = [
  [/(authorization"?\s*[:=]\s*"?)(?:bearer\s+)?[^",\s]+/gi, '$1[redacted]'],
  [/(bearer\s+)[a-z0-9._-]+/gi, '$1[redacted]'],
  [/(initData"?\s*[:=]\s*"?)[^",&\s]+/gi, '$1[redacted]'],
  [/("(?:accessToken|refreshToken|password|secret)"\s*:\s*")[^"]*/gi, '$1[redacted]'],
  [/(cookie"?\s*[:=]\s*"?)[^",\s]+/gi, '$1[redacted]'],
  [/(x-sweep-secret"?\s*[:=]\s*"?)[^",\s]+/gi, '$1[redacted]'],
  [/(x-telegram-bot-api-secret-token"?\s*[:=]\s*"?)[^",\s]+/gi, '$1[redacted]'],
];

export function redact(input: string): string {
  let out = input;
  for (const [pattern, replacement] of PATTERNS) {
    out = out.replace(pattern, replacement);
  }
  return out;
}

/** Header paths for pino redaction config. */
export const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["x-sweep-secret"]',
  'req.headers["x-telegram-bot-api-secret-token"]',
  'req.body.initData',
  'req.body.password',
  'res.headers["set-cookie"]',
];
