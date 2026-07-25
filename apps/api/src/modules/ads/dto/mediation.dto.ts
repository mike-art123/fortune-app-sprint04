import { IsIn, IsInt, IsString, MaxLength, Min, MinLength } from 'class-validator';
import { FALLBACK_REASONS, TERMINAL_REASONS } from '../ads.constants';

export class CreateMediationDto {
  @IsString() @MinLength(1) @MaxLength(64) fortuneId!: string;

  /** One per pending fortune request; makes session creation replay-safe. */
  @IsString() @MinLength(8) @MaxLength(128) idempotencyKey!: string;
}

const REPORTABLE = [...FALLBACK_REASONS, ...TERMINAL_REASONS] as string[];

export class ReportFailureDto {
  @IsInt() @Min(1) attemptNumber!: number;

  @IsString() @IsIn(REPORTABLE) reason!: string;
}
