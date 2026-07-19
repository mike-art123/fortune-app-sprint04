import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { HEADER_IDEMPOTENCY_KEY } from '../constants/headers.constants';

/**
 * Extracts a well-formed Idempotency-Key header (doc 52 §30), or null.
 * Shape is validated here so garbage never becomes a durable idempotency key;
 * a malformed key is treated as absent rather than as an error.
 */
const IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9_-]{8,128}$/;

export const IdempotencyKey = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string | null => {
    const req = ctx.switchToHttp().getRequest<{ headers: Record<string, unknown> }>();
    const raw = req.headers[HEADER_IDEMPOTENCY_KEY];
    const value = Array.isArray(raw) ? raw[0] : raw;
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return IDEMPOTENCY_KEY_PATTERN.test(trimmed) ? trimmed : null;
  },
);
