import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { ContextualRequest } from '../types/request-context';

/** Injects the correlation id of the current request. */
export const RequestId = createParamDecorator((_: unknown, ctx: ExecutionContext): string => {
  const req = ctx.switchToHttp().getRequest<ContextualRequest>();
  return req.ctx?.requestId ?? 'unknown';
});
