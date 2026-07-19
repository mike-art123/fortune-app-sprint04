import { Global, Module } from '@nestjs/common';
import { QueueHealthIndicator } from './queue-health.indicator';

/**
 * BullMQ foundation (doc 52 §22). Queues are registered here by feature phases
 * via `BullModule.registerQueue` with names from queue.constants — no workers
 * run in the foundation.
 */
@Global()
@Module({
  providers: [QueueHealthIndicator],
  exports: [QueueHealthIndicator],
})
export class QueueModule {}
