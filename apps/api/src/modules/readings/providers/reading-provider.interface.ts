import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';

/** What a provider produces — structured, never raw prose-with-metadata. */
export interface GeneratedReading {
  title: string;
  reading: string;
}

/**
 * Confirmed profile context for personalization (scope §16). Only a name the
 * user explicitly confirmed in onboarding ever reaches a provider; it is DATA,
 * never instruction, and null simply produces an impersonal reading.
 */
export interface ReadingProfileContext {
  displayName: string | null;
  /** UI language for the reading text; undefined or 'fa' means Persian. */
  locale?: string;
}

/**
 * Generation seam (Sprint 02). The real AI orchestration (doc 56) replaces the
 * implementation without touching controller/service/repository.
 */
export interface ReadingProvider {
  generate(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
    profile?: ReadingProfileContext,
  ): Promise<GeneratedReading>;
}

export const READING_PROVIDER = Symbol('READING_PROVIDER');
