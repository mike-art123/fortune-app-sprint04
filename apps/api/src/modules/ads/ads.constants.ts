/** Canonical statuses and failure reasons for rewarded-ad mediation. */

export const SESSION_STATUS = {
  created: 'created',
  attempting: 'attempting',
  rewarded: 'rewarded',
  exhausted: 'exhausted',
  cancelled: 'cancelled',
  failed: 'failed',
} as const;

export const ATTEMPT_STATUS = {
  created: 'created',
  loading: 'loading',
  shown: 'shown',
  completed: 'completed',
  verified: 'verified',
  failed: 'failed',
  skipped: 'skipped',
  cancelled: 'cancelled',
} as const;

export const ENTITLEMENT_STATUS = {
  available: 'available',
  consumed: 'consumed',
  expired: 'expired',
} as const;

/**
 * Failure reasons that allow automatically falling through to the next
 * provider. Everything else (skip, manual close, verification failure, replay,
 * global limit, cancel) stops the chain — those are user or policy decisions,
 * not provider unavailability.
 */
export const FALLBACK_REASONS = [
  'no_fill',
  'ad_unavailable',
  'provider_frequency_cap',
  'load_timeout',
  'temporary_provider_error',
  'unsupported_region',
] as const;

export type FallbackReason = (typeof FALLBACK_REASONS)[number];

export function isFallbackReason(reason: string): reason is FallbackReason {
  return (FALLBACK_REASONS as readonly string[]).includes(reason);
}

/** Non-fallback client-reported outcomes we still record on the attempt. */
export const TERMINAL_REASONS = ['skipped', 'cancelled', 'verification_failed'] as const;
