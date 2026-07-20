import {
  createPrivateKey,
  createPublicKey,
  generateKeyPairSync,
  sign as cryptoSign,
  verify as cryptoVerify,
  type KeyObject,
} from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { AppConfig } from '../../config/app.config';
import { AuthConfig } from '../../config/auth.config';
import { SecurityConfig } from '../../config/security.config';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';

/**
 * Access-token service (Sprint 04 / doc 53). Signs and verifies compact JWTs
 * with node:crypto — asymmetric only (EdDSA for ed25519 keys, RS256 for RSA).
 * There is deliberately no HS256 and no `alg: none` path.
 *
 * Key material: JWT_PRIVATE_KEY/JWT_PUBLIC_KEY (PEM). In production the env
 * schema refuses to boot without them. Outside production, a missing pair is
 * replaced by an ephemeral ed25519 keypair generated at boot — real
 * cryptography, clearly logged; tokens simply do not survive a restart.
 */

export interface AccessTokenClaims {
  iss: string;
  aud: string;
  sub: string;
  tid: string;
  roles: readonly string[];
  iat: number;
  exp: number;
}

export interface SignedAccessToken {
  accessToken: string;
  expiresInSeconds: number;
}

type SupportedAlg = 'EdDSA' | 'RS256';

const CLOCK_SKEW_SECONDS = 30;

function b64url(input: Buffer | string): string {
  return Buffer.from(input).toString('base64url');
}

@Injectable()
export class TokenService {
  private readonly privateKey: KeyObject;
  private readonly publicKey: KeyObject;
  private readonly alg: SupportedAlg;

  constructor(
    private readonly authConfig: AuthConfig,
    private readonly securityConfig: SecurityConfig,
    appConfig: AppConfig,
    private readonly logger: AppLoggerService,
  ) {
    const privatePem = authConfig.jwtPrivateKey;
    const publicPem = authConfig.jwtPublicKey;

    if (privatePem && publicPem) {
      this.privateKey = createPrivateKey(privatePem);
      this.publicKey = createPublicKey(publicPem);
      this.alg = TokenService.algorithmFor(this.privateKey);
      this.logger.info('auth.keys.loaded', { alg: this.alg });
      return;
    }

    if (appConfig.isProduction) {
      // The env schema already blocks this; defense in depth (doc 52 §55).
      throw new InfrastructureException('JWT keypair is required in production', false);
    }

    const pair = generateKeyPairSync('ed25519');
    this.privateKey = pair.privateKey;
    this.publicKey = pair.publicKey;
    this.alg = 'EdDSA';
    this.logger.warn('auth.keys.ephemeral', {
      alg: this.alg,
      note: 'JWT keypair not configured; tokens will not survive a restart',
    });
  }

  private static algorithmFor(key: KeyObject): SupportedAlg {
    switch (key.asymmetricKeyType) {
      case 'ed25519':
        return 'EdDSA';
      case 'rsa':
        return 'RS256';
      default:
        throw new InfrastructureException(
          `Unsupported JWT key type: ${String(key.asymmetricKeyType)}`,
          false,
        );
    }
  }

  private digestFor(): 'sha256' | null {
    return this.alg === 'RS256' ? 'sha256' : null;
  }

  /** Signs a new access token for `subject` (the internal user id). */
  sign(
    subject: string,
    details: { telegramId: string; roles: readonly string[] },
  ): SignedAccessToken {
    const iat = Math.floor(Date.now() / 1000);
    const ttl = this.authConfig.tokenTtlSeconds;
    const claims: AccessTokenClaims = {
      iss: this.securityConfig.jwtIssuer,
      aud: this.securityConfig.jwtAudience,
      sub: subject,
      tid: details.telegramId,
      roles: details.roles,
      iat,
      exp: iat + ttl,
    };

    const header = b64url(JSON.stringify({ alg: this.alg, typ: 'JWT' }));
    const payload = b64url(JSON.stringify(claims));
    const signingInput = `${header}.${payload}`;
    const signature = cryptoSign(this.digestFor(), Buffer.from(signingInput), this.privateKey);

    return {
      accessToken: `${signingInput}.${signature.toString('base64url')}`,
      expiresInSeconds: ttl,
    };
  }

  /** Returns the verified claims, or null for anything invalid. Never throws. */
  verify(token: string): AccessTokenClaims | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const [headerB64, payloadB64, signatureB64] = parts;

      const header = JSON.parse(Buffer.from(headerB64, 'base64url').toString('utf8')) as {
        alg?: unknown;
        typ?: unknown;
      };
      if (header.alg !== this.alg || header.typ !== 'JWT') return null;

      const valid = cryptoVerify(
        this.digestFor(),
        Buffer.from(`${headerB64}.${payloadB64}`),
        this.publicKey,
        Buffer.from(signatureB64, 'base64url'),
      );
      if (!valid) return null;

      const claims = JSON.parse(
        Buffer.from(payloadB64, 'base64url').toString('utf8'),
      ) as Partial<AccessTokenClaims>;

      const now = Math.floor(Date.now() / 1000);
      if (claims.iss !== this.securityConfig.jwtIssuer) return null;
      if (claims.aud !== this.securityConfig.jwtAudience) return null;
      if (typeof claims.sub !== 'string' || claims.sub.length === 0) return null;
      if (typeof claims.tid !== 'string' || claims.tid.length === 0) return null;
      if (!Array.isArray(claims.roles)) return null;
      if (typeof claims.exp !== 'number' || claims.exp <= now - CLOCK_SKEW_SECONDS) return null;
      if (typeof claims.iat !== 'number' || claims.iat > now + CLOCK_SKEW_SECONDS) return null;

      return claims as AccessTokenClaims;
    } catch (error) {
      // Any failure here — malformed input or a genuine verifier bug — is
      // treated as "invalid token" to callers (never throws), but is still
      // logged at debug level so the two cases stay distinguishable in
      // telemetry instead of silently collapsing into the same signal.
      this.logger.debug('auth.token.verify.rejected', {
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return null;
    }
  }
}
