import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

/** Body of POST /auth/guest — a stable, app-generated device installation id
 *  (the Android app generates a UUID once and keeps it locally). */
export class GuestLoginDto {
  @IsString()
  @MinLength(16)
  @MaxLength(128)
  @Matches(/^[A-Za-z0-9_-]+$/)
  deviceId!: string;
}
