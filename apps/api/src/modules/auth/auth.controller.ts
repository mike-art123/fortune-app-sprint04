import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { AuthService, type LoginResponse } from './auth.service';
import { TelegramLoginDto } from './dto/telegram-login.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /** The only public auth surface: exchange Telegram initData for a token. */
  @Public()
  @Post('telegram')
  @HttpCode(HttpStatus.OK)
  loginWithTelegram(@Body() dto: TelegramLoginDto): Promise<LoginResponse> {
    return this.auth.loginWithTelegram(dto.initData);
  }
}
