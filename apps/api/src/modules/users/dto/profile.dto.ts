import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/**
 * Onboarding payload (scope §16). Months arrive as the shared enum names
 * (FARVARDIN…ESFAND); deep validation and Persian-aware name normalization
 * live in UsersService so every entry path shares one rule set.
 */
export class CompleteOnboardingDto {
  @IsString() @MinLength(1) @MaxLength(80) displayName!: string;

  @IsString() @MinLength(3) @MaxLength(16) birthMonth!: string;
}

export class UpdateProfileDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(80) displayName?: string;

  @IsOptional() @IsString() @MinLength(3) @MaxLength(16) birthMonth?: string;

  /** Scope §4: switching personalization off is itself a profile edit. */
  @IsOptional() @IsBoolean() personalizationOptOut?: boolean;
}
