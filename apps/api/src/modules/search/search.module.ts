import { Module } from '@nestjs/common';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

/**
 * Search interpretation (scope §2). Depends only on config, flags and the
 * logger — the fortune catalog it routes into is a plain module import, so no
 * second source of truth appears here.
 */
@Module({
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
