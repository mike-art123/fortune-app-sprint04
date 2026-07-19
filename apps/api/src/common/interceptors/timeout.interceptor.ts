import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import { throwError, TimeoutError } from 'rxjs';
import { catchError, timeout } from 'rxjs/operators';
import { HttpStatus } from '@nestjs/common';
import { AppConfig } from '../../config/app.config';
import { DomainException } from '../exceptions/domain.exception';

/** Request timeout (doc 52 §26). Slow handlers become a normalized error. */
@Injectable()
export class TimeoutInterceptor implements NestInterceptor {
  constructor(private readonly appConfig: AppConfig) {}

  intercept(_: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(
      timeout(this.appConfig.requestTimeoutMs),
      catchError((err: unknown) =>
        throwError(() =>
          err instanceof TimeoutError
            ? new DomainException('REQUEST_TIMEOUT', 'پاسخ‌گویی بیش از حد طول کشید.', {
                status: HttpStatus.REQUEST_TIMEOUT,
                retryable: true,
              })
            : (err as Error),
        ),
      ),
    );
  }
}
