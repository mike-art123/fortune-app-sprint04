import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { FEELINGS } from '../reflection-feelings';

const ALLOWED = [...FEELINGS] as string[];

/**
 * A reflection: one of the five feelings the app offered, and whatever the
 * person wanted to write. The cap is generous — this is a diary entry, not a
 * form field — but it is still a cap, because an unbounded column is a
 * liability rather than a kindness.
 */
export class SaveReflectionDto {
  @IsOptional() @IsString() @MaxLength(64) readingId?: string;

  @IsString() @IsIn(ALLOWED) feeling!: string;

  @IsString() @MinLength(1) @MaxLength(4000) note!: string;
}

/** Which line to show. Nothing anybody typed is ever sent here. */
export class ReflectionPromptQueryDto {
  @IsString() @IsIn(ALLOWED) feeling!: string;
}

/** Cursor pagination, the same shape the history list uses. */
export class ListReflectionsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  cursor?: string;
}
