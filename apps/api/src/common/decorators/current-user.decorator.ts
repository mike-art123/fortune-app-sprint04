import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthenticatedPrincipal } from '../types/authenticated-principal';
import type { ContextualRequest } from '../types/request-context';

/** Injects the authenticated principal (doc 52 §28). */
export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthenticatedPrincipal | undefined => {
    const req = ctx.switchToHttp().getRequest<ContextualRequest>();
    return req.ctx?.principal ?? req.principal;
  },
);
