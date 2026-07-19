/** All persisted/emitted timestamps are UTC ISO-8601 (doc 52 §34). */
export function nowIso(): string {
  return new Date().toISOString();
}

export function toIso(date: Date): string {
  return date.toISOString();
}
