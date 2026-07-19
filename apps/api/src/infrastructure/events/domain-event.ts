/** Base domain event (doc 52 §31). */
export interface DomainEvent<T = unknown> {
  readonly name: string;
  readonly occurredAt: string; // UTC ISO-8601
  readonly requestId?: string;
  readonly payload: T;
}

export function createEvent<T>(name: string, payload: T, requestId?: string): DomainEvent<T> {
  return { name, occurredAt: new Date().toISOString(), requestId, payload };
}
