import { Controller, Get, Query } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { SummaryRangeQueryDto } from './dto/summary-range.query.dto';
import { HistorySummaryService, type HistorySummaryView } from './history-summary.service';

/**
 * The reader's own history, summarised (scope §6). Authenticated and scoped to
 * the caller — there is no route here that can describe anybody else. Rate
 * limited below the app default because a summary is a page visit, not a loop.
 */
@ApiTags('history')
@ApiBearerAuth()
@Controller('history')
export class HistorySummaryController {
  constructor(private readonly summaries: HistorySummaryService) {}

  @Get('summary')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  summary(
    @Query() query: SummaryRangeQueryDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<HistorySummaryView> {
    if (!principal) {
      // The global guard guarantees a principal here; this is defense in depth.
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return this.summaries.summarize(principal.userId, query.range ?? 'last30');
  }
}
