import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { InterpretSearchDto } from './dto/interpret-search.dto';
import { SearchService } from './search.service';
import type { SearchInterpretation } from './search-interpretation';

/**
 * The AI stage of search (scope §2). Authenticated, and rate limited well
 * below the app default — the client only asks after its own rules found
 * nothing, and only when someone deliberately submits.
 */
@ApiTags('search')
@ApiBearerAuth()
@Controller('search')
export class SearchController {
  constructor(private readonly search: SearchService) {}

  @Post('interpret')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  interpret(@Body() dto: InterpretSearchDto): Promise<SearchInterpretation> {
    return this.search.interpret(dto.query);
  }
}
