/**
 * Pure provider-ordering logic (unit-testable, no I/O).
 *
 * Starts from the configured priority, drops providers that are not
 * configured, then demotes (never removes) providers whose recent consecutive
 * failures crossed the cooldown threshold — a cooled-down provider still gets
 * a chance, but only after the healthy ones.
 */
export interface ProviderHealth {
  provider: string;
  recentConsecutiveFailures: number;
}

export function orderProviders(
  configuredOrder: string[],
  isConfigured: (provider: string) => boolean,
  health: ProviderHealth[],
  cooldownThreshold: number,
): string[] {
  const available = configuredOrder.filter((p) => isConfigured(p));
  const failuresOf = (p: string): number =>
    health.find((h) => h.provider === p)?.recentConsecutiveFailures ?? 0;
  const healthy = available.filter((p) => failuresOf(p) < cooldownThreshold);
  const cooled = available.filter((p) => failuresOf(p) >= cooldownThreshold);
  return [...healthy, ...cooled];
}
