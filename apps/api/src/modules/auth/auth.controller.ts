import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { AuthService, type LoginResponse } from './auth.service';
import { GuestLoginDto } from './dto/guest-login.dto';
import { TelegramLoginDto } from './dto/telegram-login.dto';

/**
 * Auth surface (Sprint 04 / doc 53 + Play build): public routes that exchange
 * a proof of identity for a signed access token — Telegram initData for the
 * Mini App, a device id for the Android app (dark behind the auth.guest
 * flag). Everything downstream of login is guarded by the global auth guard.
 */
@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /** Exchange Telegram initData for a token (the Mini App login). */
  @Public()
  @Post('telegram')
  @HttpCode(HttpStatus.OK)
  loginWithTelegram(@Body() dto: TelegramLoginDto): Promise<LoginResponse> {
    return this.auth.loginWithTelegram(dto.initData);
  }

  /** Exchange a device id for a token (the Play build's guest login). */
  @Public()
  @Post('guest')
  @HttpCode(HttpStatus.OK)
  loginAsGuest(@Body() dto: GuestLoginDto): Promise<LoginResponse> {
    return this.auth.loginAsGuest(dto.deviceId);
  }
}
