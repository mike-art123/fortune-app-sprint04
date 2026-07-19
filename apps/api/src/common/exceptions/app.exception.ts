import { HttpStatus } from '@nestjs/common';
import type { ErrorCode } from '../constants/error-codes.constants';

/**
 * Base application exception (doc 52 §13). Carries a stable code, a safe
 * client message, and a developer message that is logged but never exposed.
 */
export abstract class AppException extends Error {
  protected constructor(
    readonly code: ErrorCode,
    readonly status: HttpStatus,
    readonly safeMessage: string,
    readonly developerMessage?: string,
    readonly retryable: boolean = false,
    readonly metadata?: Record<string, unknown>,
  ) {
    super(developerMessage ?? safeMessage);
    this.name = new.target.name;
  }
}
