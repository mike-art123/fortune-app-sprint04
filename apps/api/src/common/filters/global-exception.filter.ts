import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Response } from 'express';
import type { ErrorCode } from '../constants/error-codes.constants';
import { AppException } from '../exceptions/app.exception';
import type { ApiErrorBody } from '../types/api-error';
import type { ContextualRequest } from '../types/request-context';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';

const STATUS_TO_CODE: Record<number, ErrorCode> = {
  400: 'VALIDATION_FAILED',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  408: 'REQUEST_TIMEOUT',
  409: 'CONFLICT',
  422: 'VALIDATION_FAILED',
  429: 'RATE_LIMIT',
};

const SAFE_MESSAGES: Partial<Record<ErrorCode, string>> = {
  VALIDATION_FAILED: 'درخواست کامل نیست؛ ورودی‌ها را بررسی کن.',
  UNAUTHORIZED: 'برای ادامه باید وارد شوی.',
  FORBIDDEN: 'دسترسی به این بخش مجاز نیست.',
  NOT_FOUND: 'موردی که دنبالش بودی پیدا نشد.',
  CONFLICT: 'این درخواست قبلاً ثبت شده است.',
  RATE_LIMIT: 'کمی صبر کن و دوباره تلاش کن.',
  REQUEST_TIMEOUT: 'پاسخ‌گویی بیش از حد طول کشید.',
  INTERNAL: 'مشکلی پیش آمد؛ لطفاً دوباره تلاش کن.',
};

/**
 * Normalizes every error into the stable contract (doc 52 §12/§13).
 * Known app exceptions, Nest HTTP exceptions, validation errors, and Prisma
 * errors each map explicitly; anything unknown becomes a safe INTERNAL error.
 */
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private readonly logger: AppLoggerService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const res = http.getResponse<Response>();
    const req = http.getRequest<ContextualRequest>();
    const requestId = req.ctx?.requestId ?? null;

    const { status, body } = this.normalize(exception, requestId);

    if (status >= 500) {
      this.logger.error('unhandled_exception', {
        requestId,
        path: req.url,
        error: exception instanceof Error ? exception.message : String(exception),
      });
    }

    res.status(status).json(body);
  }

  private normalize(
    exception: unknown,
    requestId: string | null,
  ): { status: number; body: ApiErrorBody } {
    // 1) Our own exception hierarchy
    if (exception instanceof AppException) {
      return this.body(exception.status, exception.code, exception.safeMessage, requestId, {
        retryable: exception.retryable,
      });
    }

    // 2) Validation pipe output (BadRequestException with message array)
    if (exception instanceof BadRequestException) {
      const response = exception.getResponse();
      const details =
        typeof response === 'object' &&
        response !== null &&
        Array.isArray((response as { message?: unknown }).message)
          ? (response as { message: unknown[] }).message
          : undefined;
      return this.body(400, 'VALIDATION_FAILED', SAFE_MESSAGES.VALIDATION_FAILED ?? '', requestId, {
        details,
      });
    }

    // 3) Other Nest HTTP exceptions
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const code = STATUS_TO_CODE[status] ?? 'INTERNAL';
      return this.body(
        status,
        code,
        SAFE_MESSAGES[code] ?? SAFE_MESSAGES.INTERNAL ?? '',
        requestId,
      );
    }

    // 4) Prisma known errors — never leak SQL or model internals
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') {
        return this.body(409, 'CONFLICT', SAFE_MESSAGES.CONFLICT ?? '', requestId);
      }
      if (exception.code === 'P2025') {
        return this.body(404, 'NOT_FOUND', SAFE_MESSAGES.NOT_FOUND ?? '', requestId);
      }
      return this.body(500, 'INTERNAL', SAFE_MESSAGES.INTERNAL ?? '', requestId, {
        retryable: true,
      });
    }

    // 5) Unknown — generic internal error, details stay in logs only
    return this.body(
      HttpStatus.INTERNAL_SERVER_ERROR,
      'INTERNAL',
      SAFE_MESSAGES.INTERNAL ?? '',
      requestId,
      {
        retryable: true,
      },
    );
  }

  private body(
    status: number,
    code: ErrorCode,
    message: string,
    requestId: string | null,
    extra?: { details?: unknown[]; retryable?: boolean },
  ): { status: number; body: ApiErrorBody } {
    return {
      status,
      body: {
        success: false,
        error: {
          code,
          message,
          ...(extra?.details !== undefined ? { details: extra.details } : {}),
          ...(extra?.retryable !== undefined ? { retryable: extra.retryable } : {}),
        },
        requestId,
      },
    };
  }
}
