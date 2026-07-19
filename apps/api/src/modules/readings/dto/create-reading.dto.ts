import { Type } from 'class-transformer';
import {
  IsObject,
  IsOptional,
  IsString,
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
}

export class CreateReadingDto {
  @IsString() @MinLength(1) @MaxLength(64) fortuneId!: string;

  @IsObject()
  @ValidateNested()
  @Type(() => ReadingInputDto)
  input!: ReadingInputDto;
}
