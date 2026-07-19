import { Injectable } from '@nestjs/common';
import { AppLoggerService } from '../logging/app-logger.service';
import type { DomainEvent } from './domain-event';

type Handler = (event: DomainEvent) => Promise<void> | void;

/**
 * In-process event bus (doc 52 §31). Events crossing reliability boundaries
 * must go through the outbox instead. No external broker in the foundation.
 */
@Injectable()
export class EventBusService {
  private readonly handlers = new Map<string, Handler[]>();

  constructor(private readonly logger: AppLoggerService) {}

  subscribe(eventName: string, handler: Handler): void {
    const list = this.handlers.get(eventName) ?? [];
    list.push(handler);
    this.handlers.set(eventName, list);
  }

  async publish(event: DomainEvent): Promise<void> {
    const list = this.handlers.get(event.name) ?? [];
    for (const handler of list) {
      try {
        await handler(event);
      } catch (error) {
        // A failing subscriber never breaks the publisher's transaction result.
        this.logger.error('event_handler_failed', {
          event: event.name,
          requestId: event.requestId,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  }
}
