import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import type { Request } from 'express';
import { HEADER_CLIENT_VERSION, HEADER_PLATFORM } from '../constants/headers.constants';
import type { ContextualRequest, RequestContext } from '../types/request-context';

/** Builds the request-scoped context object (doc 52 §15). */
@Injectable()
export class RequestContextInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context
      .switchToHttp()
      .getRequest<Request & ContextualRequest & { requestId?: string }>();

    const header = (name: string): string | undefined => {
      const v = req.headers[name];
      return Array.isArray(v) ? v[0] : v;
    };

    const ctx: RequestContext = {
      requestId: req.requestId ?? 'unknown',
      locale: header('accept-language')?.split(',')[0],
      clientIp: req.ip ?? req.socket?.remoteAddress,
      userAgent: header('user-agent'),
      appVersion: header(HEADER_CLIENT_VERSION),
      platform: header(HEADER_PLATFORM),
      isTelegram: header(HEADER_PLATFORM) === 'telegram',
      principal: req.principal,
      startedAt: Date.now(),
    };
    req.ctx = ctx;
    return next.handle();
  }
}
