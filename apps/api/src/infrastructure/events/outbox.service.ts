import { Injectable } from '@nestjs/common';
import type { TransactionClient } from '../database/transaction.service';
import type { DomainEvent } from './domain-event';

/**
 * Outbox hook (doc 52 §32): events are persisted in the same transaction as
 * the state change, so neither can exist without the other. The polling
 * dispatcher worker is deliberately deferred to a later phase.
 */
@Injectable()
export class OutboxService {
  async record(tx: TransactionClient, event: DomainEvent): Promise<void> {
    await tx.outboxEvent.create({
      data: {
        name: event.name,
        payload: JSON.stringify(event.payload),
        requestId: event.requestId ?? null,
        occurredAt: new Date(event.occurredAt),
      },
    });
  }
}
