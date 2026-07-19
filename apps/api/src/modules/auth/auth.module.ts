import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TelegramTokenVerifier } from './telegram-token.verifier';
import { TOKEN_VERIFIER } from './token-verifier.interface';
import { TokenService } from './token.service';

/**
 * Real auth (Sprint 04 / doc 53): Telegram initData → JWT lifecycle behind the
 * doc 52 §28 seam. DenyAllTokenVerifier remains available as an explicit test
 * seam only — it is no longer wired anywhere.
 */
@Module({
  imports: [UsersModule],
  controllers: [AuthController],
  providers: [
    TokenService,
    AuthService,
    TelegramTokenVerifier,
    { provide: TOKEN_VERIFIER, useExisting: TelegramTokenVerifier },
  ],
  exports: [TOKEN_VERIFIER],
})
export class AuthModule {}
