import { IsString, MaxLength, MinLength } from 'class-validator';

/**
 * One typed question. Capped short: this route classifies a search box, not a
 * conversation, and a cap is also a cost ceiling.
 */
export class InterpretSearchDto {
  @IsString() @MinLength(2) @MaxLength(120) query!: string;
}
