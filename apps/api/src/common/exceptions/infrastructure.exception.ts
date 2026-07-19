import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

/** Infrastructure failures normalized to a safe internal error (doc 52 §13). */
export class InfrastructureException extends AppException {
  constructor(developerMessage: string, retryable = true) {
    super(
      'INTERNAL',
      HttpStatus.INTERNAL_SERVER_ERROR,
      'مشکلی پیش آمد؛ لطفاً دوباره تلاش کن.',
      developerMessage,
      retryable,
    );
  }
}
