import { Injectable } from '@nestjs/common';
import { extractJsonObject } from '../../../common/json/extract-json-object';
import { dateKeyFor } from '../../../common/utils/daily-window.util';
import { AiConfig } from '../../../config/ai.config';
import { MonetizationConfig } from '../../../config/monetization.config';
import { FeatureFlagsService } from '../../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type {
  GeneratedReading,
  ReadingProfileContext,
  ReadingProvider,
} from '../providers/reading-provider.interface';
import { QURAN_VERSES, type QuranVerse } from './quran-deck';
import { buildQuranPrompt } from './quran-prompt';
import { drawVerse } from './quran-selection';
import * as labels from '../providers/reading-labels';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const QURAN_RAW_ENGINE_FLAG = 'quran.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;

class QuranRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'QuranRequestError';
  }
}

/** The model's half of the schema; the verse and its translation are ours to
 *  draw and add. */
interface QuranModelReading {
  reflectionForIntention: string;
  hope: string;
  practicalAdvice: string;
}

/**
 * The Quran tafa'ul raw engine, worn as a decorator over the ordinary provider
 * so nothing outside this folder learns a new name. Every fortune that is not
 * quran — and quran itself while the flag is off or no model is configured —
 * passes straight through.
 *
 * When it runs, the stable draw picks today's verse for this intention, the
 * real (dual-source-verified) verse and its translation ride in the prompt,
 * and the reading always states the drawn verse, never one the model named.
 * This is تفأل — reflection, never a verdict — and the humility note keeps it
 * so. Like the provider it wraps, this engine fails honestly.
 */
@Injectable()
export class QuranReadingProvider implements ReadingProvider {
  constructor(
    private readonly inner: ReadingProvider,
    private readonly flags: FeatureFlagsService,
    private readonly config: AiConfig,
    private readonly monetization: MonetizationConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async generate(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
    profile?: ReadingProfileContext,
  ): Promise<GeneratedReading> {
    if (fortune.id !== 'quran') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(QURAN_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.quran.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const index = drawVerse({
      dateKey,
      intention: input.intention ?? '',
      deckSize: QURAN_VERSES.length,
    });
    const verse = QURAN_VERSES[index];
    if (!verse) {
      // Unreachable — the draw is bounded by the set length — but the index
      // signature is `T | undefined`, and a raw engine never guesses a verse.
      throw new QuranRequestError(`draw fell outside the set at ${index}`, false);
    }
    const messages = buildQuranPrompt(verse, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseQuranReading(content);
        this.logger.info('reading.quran.succeeded', {
          verseId: verse.id,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(verse, parsed, profile?.locale);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof QuranRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.quran.retrying', {
          verseId: verse.id,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.quran.failed', {
      verseId: verse.id,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new QuranRequestError('quran generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildQuranPrompt>): Promise<string> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const baseUrl = this.config.baseUrl.replace(/\/+$/, '');
      const response = await fetch(`${baseUrl}/chat/completions`, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.model,
          temperature: 0.8,
          max_tokens: 2000,
          response_format: { type: 'json_object' },
          messages,
        }),
      });

      if (!response.ok) {
        if (MISCONFIGURED_STATUS.has(response.status)) {
          this.logger.error('reading.quran.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new QuranRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new QuranRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof QuranRequestError) throw error;
      if (controller.signal.aborted) {
        throw new QuranRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new QuranRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * Validates the model's half of the reading — three non-empty sections — and
 * caps each so a runaway completion cannot bloat the stored reading. The verse
 * and its translation are never taken from here; the set owns them.
 */
export function parseQuranReading(raw: string): QuranModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new QuranRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof QuranModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new QuranRequestError(`completion is missing ${key}`, true);
    }
    return text.slice(0, MAX_SECTION_CHARS);
  };

  return {
    reflectionForIntention: section('reflectionForIntention'),
    hope: section('hope'),
    practicalAdvice: section('practicalAdvice'),
  };
}

/**
 * Flattens the schema into the reading text the client already renders: the
 * verse and its translation first — the fal IS the verse — then a gentle
 * reflection, the «برای امروز:» promise, and finally the humility note that
 * keeps this تفأل and not a verdict. The verse and translation are ours,
 * never the model's.
 */
function composeReading(
  verse: QuranVerse,
  parsed: QuranModelReading,
  locale?: string,
): GeneratedReading {
  const advice = labels.stripForToday(parsed.practicalAdvice);
  return {
    title: labels.quranTitle(verse.surahNameFa, locale),
    reading: [
      labels.quranReference(verse.surahNameFa, verse.ayah, locale),
      // The verse is the source and stays in its own script for everyone.
      verse.arabic,
      // Its translation exists in Persian only; a Turkish reader is better
      // served by the reflection below than by a line they cannot read.
      ...(labels.showsPersianSource(locale)
        ? [labels.quranTranslation(verse.translator, verse.translationFa, locale)]
        : []),
      parsed.reflectionForIntention,
      parsed.hope,
      `${labels.forToday(locale)} ${advice}`,
      labels.quranHumility(locale),
    ].join('\n\n'),
  };
}
