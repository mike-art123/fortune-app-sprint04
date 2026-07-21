import type { AuthenticatedPrincipal } from './authenticated-principal';

/**
 * Request-scoped context (doc 52 §15). Domain code receives this instead of
 * raw Express request objects.
 */
export interface RequestContext {
  requestId: string;
  principal?: AuthenticatedPrincipal;
  locale?: string;
  clientIp?: string;
  userAgent?: string;
  appVersion?: string;
  platform?: string;
  isTelegram: boolean;
  startedAt: number;
}

/** Express request augmented with our context. Transport layer only. */
export interface ContextualRequest {
  ctx?: RequestContext;
  /**
   * Set by the auth guard, which runs BEFORE the request-context interceptor
   * (Nest order: middleware → guards → interceptors). Storing the principal
   * directly on the request lets it survive that gap; the interceptor then
   * copies it into `ctx`, and `@CurrentUser` reads either.
   */
  principal?: AuthenticatedPrincipal;
  headers: Record<string, string | string[] | undefined>;
  method: string;
  url: string;
  ip?: string;
  socket?: { remoteAddress?: string };
}
