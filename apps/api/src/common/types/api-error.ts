import type { ErrorCode } from '../constants/error-codes.constants';

/** Public error contract (doc 52 §12, superset of doc 33). */
export interface ApiErrorBody {
  success: false;
  error: {
    code: ErrorCode;
    message: string;
    details?: unknown[];
    retryable?: boolean;
  };
  requestId: string | null;
}
