import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import type { ContextualRequest } from '../types/request-context';

/**
 * Success envelope (docs 33 + 52 §35): { success, data, meta: { requestId } }.
 * Handlers may opt out by returning an already-enveloped object.
 */
@Injectable()
export class ResponseMetadataInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<ContextualRequest>();
    return next.handle().pipe(
      map((payload) => {
        if (payload && typeof payload === 'object' && 'success' in (payload as object)) {
          return payload;
        }
        return {
          success: true,
          data: payload ?? null,
          meta: { requestId: req.ctx?.requestId ?? null },
        };
      }),
    );
  }
}
