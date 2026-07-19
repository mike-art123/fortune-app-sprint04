// Canonical API contract shared by client and server (doc 33).
export interface ApiSuccess<T> { success: true; data: T; meta?: Record<string, unknown>; }
export interface ApiError {
  success: false;
  error: { code: ApiErrorCode; message: string };
  requestId?: string;
}
export type ApiResponse<T> = ApiSuccess<T> | ApiError;

export const API_ERROR_CODES = [
  'INVALID_INPUT', 'UNAUTHORIZED', 'FORBIDDEN', 'NOT_FOUND', 'RATE_LIMIT',
  'INSUFFICIENT_COINS', 'SUBSCRIPTION_REQUIRED', 'READING_FAILED', 'AI_TIMEOUT',
  'AD_VERIFICATION_FAILED', 'DUPLICATE_REQUEST', 'INTERNAL',
] as const;
export type ApiErrorCode = (typeof API_ERROR_CODES)[number];

export interface Paginated<T> { items: T[]; nextCursor?: string | null; }
