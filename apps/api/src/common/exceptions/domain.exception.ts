import { HttpStatus } from '@nestjs/common';
import type { ErrorCode } from '../constants/error-codes.constants';
import { AppException } from './app.exception';

/** Business-rule violations (doc 52 §13). */
export class DomainException extends AppException {
  constructor(
    code: ErrorCode,
    safeMessage: string,
    options?: {
      status?: HttpStatus;
      developerMessage?: string;
      retryable?: boolean;
      metadata?: Record<string, unknown>;
    },
  ) {
    super(
      code,
      options?.status ?? HttpStatus.UNPROCESSABLE_ENTITY,
      safeMessage,
      options?.developerMessage,
      options?.retryable ?? false,
      options?.metadata,
    );
  }
}
