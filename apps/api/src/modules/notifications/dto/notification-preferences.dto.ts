import { IsBoolean, IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

/** IANA zones this app actually serves. A closed list keeps a typo — or an
 * attempt to smuggle something odd into `Intl` — out of the database. */
const ZONES = ['Asia/Tehran', 'UTC', 'Europe/Berlin', 'Europe/London', 'America/New_York'];

/**
 * Every field is optional and every one is a limit (scope §7): what to hear,
 * when not to be disturbed, and how much at most. Omitted fields are left
 * exactly as they were.
 */
export class UpdateNotificationPreferencesDto {
  @IsOptional() @IsBoolean() dailyFortune?: boolean;

  @IsOptional() @IsBoolean() streakReminder?: boolean;

  @IsOptional() @IsBoolean() weeklySummary?: boolean;

  @IsOptional() @IsInt() @Min(0) @Max(23) quietFromHour?: number;

  @IsOptional() @IsInt() @Min(0) @Max(23) quietToHour?: number;

  /** Zero is a valid answer: it means "keep the settings, send nothing". */
  @IsOptional() @IsInt() @Min(0) @Max(5) dailyCap?: number;

  @IsOptional() @IsIn(ZONES) timeZone?: string;

  /** Silence from now. 0 lifts it; a week is the longest single mute. */
  @IsOptional() @IsInt() @Min(0) @Max(168) muteHours?: number;
}
