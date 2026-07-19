/** Typed queue names (doc 52 §22). Real workers arrive in feature phases. */
export const QUEUE_NAMES = {
  readingGeneration: 'reading-generation',
  notifications: 'notifications',
  analytics: 'analytics',
  maintenance: 'maintenance',
} as const;

export type QueueName = (typeof QUEUE_NAMES)[keyof typeof QUEUE_NAMES];

/**
 * Every job payload is versioned and carries the correlation id (doc 52 §23).
 * Sensitive content is referenced by id, never embedded.
 */
export interface VersionedJob {
  version: number;
  requestId: string;
}

/** Default retry policy: bounded attempts with exponential backoff. */
export const DEFAULT_JOB_OPTIONS = {
  attempts: 3,
  backoff: { type: 'exponential' as const, delay: 2000 },
  removeOnComplete: 1000,
  removeOnFail: 5000,
};
