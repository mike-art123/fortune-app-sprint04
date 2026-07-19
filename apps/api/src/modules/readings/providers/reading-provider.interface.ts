import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';

/** What a provider produces — structured, never raw prose-with-metadata. */
export interface GeneratedReading {
  title: string;
  reading: string;
}

/**
 * Generation seam (Sprint 02). The real AI orchestration (doc 56) replaces the
 * implementation without touching controller/service/repository.
 */
export interface ReadingProvider {
  generate(fortune: FortuneCatalogEntry, input: ReadingInputDto): Promise<GeneratedReading>;
}

export const READING_PROVIDER = Symbol('READING_PROVIDER');
