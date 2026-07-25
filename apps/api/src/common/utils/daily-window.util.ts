/**
 * Backend-authoritative daily window for the free-allowance reset.
 *
 * The day boundary is derived from a configurable IANA timezone using the
 * server clock — the device clock is never trusted. `dateKeyFor` yields a
 * stable `YYYY-MM-DD` bucket for a given instant in that zone; `nextResetAt`
 * returns the exact instant that bucket rolls over (local midnight, as UTC).
 */
export function dateKeyFor(now: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const get = (type: string): string => parts.find((p) => p.type === type)?.value ?? '';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

export function nextResetAt(now: Date, timeZone: string): Date {
  const offsetMs = tzOffsetMs(now, timeZone);
  // Wall-clock time in the target zone, expressed as a UTC-shifted date so we
  // can read its calendar fields directly.
  const local = new Date(now.getTime() + offsetMs);
  const nextLocalMidnight = Date.UTC(
    local.getUTCFullYear(),
    local.getUTCMonth(),
    local.getUTCDate() + 1,
  );
  return new Date(nextLocalMidnight - offsetMs);
}

/** Offset (ms) between wall-clock time in `timeZone` and UTC at `now`. */
function tzOffsetMs(now: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(now);
  const map: Record<string, number> = {};
  for (const p of parts) {
    if (p.type !== 'literal') map[p.type] = Number(p.value);
  }
  const asUtc = Date.UTC(map.year, map.month - 1, map.day, map.hour, map.minute, map.second);
  return asUtc - now.getTime();
}
