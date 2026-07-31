import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { HEADER_ACCEPT_LANGUAGE } from '../constants/headers.constants';
import type { ContextualRequest } from '../types/request-context';

/**
 * Injects the client's UI language (the `accept-language` header), first tag
 * only, lowercased — or null when the header is absent or blank. Read straight
 * from the headers so the value exists regardless of interceptor order.
 */
export const AcceptLanguage = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string | null => {
    const req = ctx.switchToHttp().getRequest<ContextualRequest>();
    const raw = req.headers[HEADER_ACCEPT_LANGUAGE];
    const value = Array.isArray(raw) ? raw[0] : raw;
    const tag = value?.split(',')[0]?.trim().toLowerCase() ?? '';
    return tag.length > 0 ? tag : null;
  },
);
