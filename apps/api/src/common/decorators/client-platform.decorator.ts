import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { HEADER_PLATFORM } from '../constants/headers.constants';
import type { ContextualRequest } from '../types/request-context';

/**
 * Injects the client platform (the `x-platform` header), lowercased, or null
 * when the header is absent or blank. Read straight from the headers so the
 * value exists regardless of interceptor order.
 */
export const ClientPlatform = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string | null => {
    const req = ctx.switchToHttp().getRequest<ContextualRequest>();
    const raw = req.headers[HEADER_PLATFORM];
    const value = Array.isArray(raw) ? raw[0] : raw;
    const platform = value?.trim().toLowerCase() ?? '';
    return platform.length > 0 ? platform : null;
  },
);
