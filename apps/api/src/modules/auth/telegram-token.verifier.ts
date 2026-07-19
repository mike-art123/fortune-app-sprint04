import { Injectable } from '@nestjs/common';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import type { TokenVerifier } from './token-verifier.interface';
import { TokenService } from './token.service';

/**
 * The real production verifier (Sprint 04 / doc 53): a bearer token is valid
 * iff it is a JWT signed by us with live iss/aud/exp claims. Replaces
 * DenyAllTokenVerifier behind the same seam — the guard is untouched.
 */
@Injectable()
export class TelegramTokenVerifier implements TokenVerifier {
  constructor(private readonly tokens: TokenService) {}

  async verify(bearerToken: string): Promise<AuthenticatedPrincipal | null> {
    const claims = this.tokens.verify(bearerToken);
    if (!claims) return null;
    return {
      userId: claims.sub,
      telegramId: claims.tid,
      roles: claims.roles,
    };
  }
}
