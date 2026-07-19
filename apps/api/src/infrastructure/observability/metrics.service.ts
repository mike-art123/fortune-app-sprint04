import { Injectable } from '@nestjs/common';

/**
 * Vendor-free metrics hook (doc 52 §37). In-process counters now; a real
 * exporter can replace the internals without touching call sites.
 */
@Injectable()
export class MetricsService {
  private readonly counters = new Map<string, number>();

  increment(name: string, by = 1): void {
    this.counters.set(name, (this.counters.get(name) ?? 0) + by);
  }

  snapshot(): Record<string, number> {
    return Object.fromEntries(this.counters);
  }
}
