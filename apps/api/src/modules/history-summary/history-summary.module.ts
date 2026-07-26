import { Module } from '@nestjs/common';
import { ReadingsModule } from '../readings/readings.module';
import { UsersModule } from '../users/users.module';
import { HistorySummaryController } from './history-summary.controller';
import { HistorySummaryService } from './history-summary.service';

/**
 * History summary (scope §6). It owns no readings of its own: it counts
 * through the readings repository and asks the users service whether this
 * reader wants anything of theirs sent anywhere.
 */
@Module({
  imports: [ReadingsModule, UsersModule],
  controllers: [HistorySummaryController],
  providers: [HistorySummaryService],
})
export class HistorySummaryModule {}
