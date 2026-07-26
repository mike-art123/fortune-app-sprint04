import { IsIn, IsOptional } from 'class-validator';
import { SUMMARY_RANGES, type SummaryRange } from '../history-digest';

const RANGES = [...SUMMARY_RANGES] as string[];

/**
 * The window to look back over. A closed list: anything else is refused before
 * it can reach a query.
 */
export class SummaryRangeQueryDto {
  @IsOptional() @IsIn(RANGES) range?: SummaryRange;
}
