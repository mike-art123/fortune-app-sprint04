/** The UI languages the product speaks (phase E). Persian is the default. */
export const SUPPORTED_LOCALES = ['fa', 'en', 'ar', 'tr'] as const;
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];

/**
 * Maps a raw language tag ("en-US", "FA", "tr,en;q=0.9") to a supported
 * locale, or undefined when nothing supported was asked for. Undefined means
 * "leave things as they are" — never a downgrade to a default.
 */
export function normalizeLocale(raw: string | undefined): SupportedLocale | undefined {
  if (!raw) return undefined;
  const primary = raw.split(',')[0]?.split(';')[0]?.trim().toLowerCase() ?? '';
  const base = primary.split('-')[0];
  return (SUPPORTED_LOCALES as readonly string[]).includes(base)
    ? (base as SupportedLocale)
    : undefined;
}
