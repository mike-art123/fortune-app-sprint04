import { CanActivate, ExecutionContext, Inject, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../constants/metadata.constants';
import { DomainException } from '../exceptions/domain.exception';
import { HttpStatus } from '@nestjs/common';
import type { ContextualRequest } from '../types/request-context';
import { TOKEN_VERIFIER, type TokenVerifier } from '../../modules/auth/token-verifier.interface';

/**
 * Global auth guard (doc 52 §28). Routes marked @Public skip verification.
 * Everything else requires a bearer token accepted by the injected verifier.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    @Inject(TOKEN_VERIFIER) private readonly verifier: TokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const req = context.switchToHttp().getRequest<ContextualRequest>();
    const header = req.headers['authorization'];
    const raw = Array.isArray(header) ? header[0] : header;
    const token = raw?.startsWith('Bearer ') ? raw.slice(7) : undefined;

    const principal = token ? await this.verifier.verify(token) : null;
    if (!principal) {
      throw new DomainException('UNAUTHORIZED', 'برای ادامه باید وارد شوی.', {
        status: HttpStatus.UNAUTHORIZED,
      });
    }
    if (req.ctx) req.ctx.principal = principal;
    return true;
  }
}
