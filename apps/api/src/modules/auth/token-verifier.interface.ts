import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';

/**
 * Verification seam (doc 52 §28/§29). Sprint 04 wires TelegramTokenVerifier
 * (JWT) as the live implementation; the guard depends only on this interface.
 */
export interface TokenVerifier {
  verify(bearerToken: string): Promise<AuthenticatedPrincipal | null>;
}

export const TOKEN_VERIFIER = Symbol('TOKEN_VERIFIER');

/**
 * Test seam / explicit fallback: rejects every token. Not wired in any
 * environment since Sprint 04 — kept so tests can override TOKEN_VERIFIER
 * with a verifier that is deliberately closed (an insecure mock-accept in
 * production is prohibited, §55).
 */
export class DenyAllTokenVerifier implements TokenVerifier {
  async verify(): Promise<null> {
    return null;
  }
}
