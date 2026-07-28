import { Type } from 'class-transformer';
import {
  IsObject,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

/** The offering payload. Per-fortune completeness is enforced in the service
 *  against the server catalog; this DTO enforces shape and bounds only. */
export class ReadingInputDto {
  @IsOptional() @IsString() @MaxLength(300) intention?: string;
  @IsOptional() @IsString() @MaxLength(2000) narration?: string;
  @IsOptional() @IsString() @MaxLength(60) selfName?: string;
  @IsOptional() @IsString() @MaxLength(60) otherName?: string;

  /** Coffee only: a downscaled cup photo as a data URL. The vision model reads
   *  it once; it is NEVER persisted (privacy, and it would bloat every row) —
   *  the service strips it before storing. Bound generously because the client
   *  already downscales; the bound only guards against abuse. */
  @IsOptional()
  @IsString()
  @MaxLength(5_000_000)
  @Matches(/^data:image\/(jpeg|png|webp);base64,/, {
    message: 'imageDataUrl must be a base64 image data URL',
  })
  imageDataUrl?: string;
}

export class CreateReadingDto {
  @IsString() @MinLength(1) @MaxLength(64) fortuneId!: string;

  /** One-time rewarded-ad unlock id (verified server-side, single-use). */
  @IsOptional() @IsString() @MaxLength(64) adEntitlementId?: string;

  @IsObject()
  @ValidateNested()
  @Type(() => ReadingInputDto)
  input!: ReadingInputDto;
}
