import { IsString, MaxLength, MinLength } from 'class-validator';

/** Body of POST /auth/telegram — the raw initData string from the Mini App. */
export class TelegramLoginDto {
  @IsString()
  @MinLength(1)
  @MaxLength(4096)
  initData!: string;
}
