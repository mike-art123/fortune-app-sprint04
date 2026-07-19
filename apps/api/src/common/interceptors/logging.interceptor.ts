import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import type { ContextualRequest } from '../types/request-context';

/**
 * Structured request log (doc 52 §16): method, path, status, duration,
 * request id, principal id. Bodies are never logged here.
 */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  constructor(private readonly logger: AppLoggerService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<ContextualRequest>();
    const res = context.switchToHttp().getResponse<{ statusCode: number }>();
    const started = req.ctx?.startedAt ?? Date.now();

    return next.handle().pipe(
      tap({
        next: () => this.write(req, res.statusCode, started),
        error: () => this.write(req, res.statusCode >= 400 ? res.statusCode : 500, started),
      }),
    );
  }

  private write(req: ContextualRequest, status: number, started: number): void {
    this.logger.info('http_request', {
      method: req.method,
      path: req.url,
      status,
      durationMs: Date.now() - started,
      requestId: req.ctx?.requestId,
      principalId: req.ctx?.principal?.userId,
      appVersion: req.ctx?.appVersion,
    });
  }
}
