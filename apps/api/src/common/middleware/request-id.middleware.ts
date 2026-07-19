import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { HEADER_REQUEST_ID } from '../constants/headers.constants';

const SAFE_ID = /^[A-Za-z0-9-]{8,64}$/;

/**
 * Ensures every request carries a correlation id (doc 52 §14).
 * Incoming ids are accepted only when well-formed; hostile values are replaced.
 */
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const incoming = req.headers[HEADER_REQUEST_ID];
    const candidate = Array.isArray(incoming) ? incoming[0] : incoming;
    const requestId = candidate && SAFE_ID.test(candidate) ? candidate : randomUUID();

    (req as Request & { requestId: string }).requestId = requestId;
    res.setHeader(HEADER_REQUEST_ID, requestId);
    next();
  }
}
