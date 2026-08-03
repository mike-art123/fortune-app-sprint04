import { Injectable } from '@nestjs/common';
import { extractJsonObject } from '../../../common/json/extract-json-object';
import { AiConfig } from '../../../config/ai.config';
import { FeatureFlagsService } from '../../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type {
  GeneratedReading,
  ReadingProfileContext,
  ReadingProvider,
} from '../providers/reading-provider.interface';
import { buildAbjadPrompt } from './abjad-prompt';
import { computeAbjad, renderBreakdown, type AbjadResult } from './abjad-numerology';
import * as labels from '../providers/reading-labels';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const ABJAD_RAW_ENGINE_FLAG = 'abjad.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;
/** Past this many letters the per-letter working is noise; show the sum alone. */
const MAX_BREAKDOWN_LETTERS = 24;

class AbjadRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'AbjadRequestError';
  }
}

/** The model's half of the schema; the number is ours to compute and add. */
interface AbjadModelReading {
  numberMeaning: string;
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The abjad raw engine, worn as a decorator over the ordinary provider so
 * nothing outside this folder learns a new name. Every fortune that is not
 * abjad — and abjad itself while the flag is off or no model is configured —
 * passes straight through.
 *
 * When it runs, the abjad-kabir number is counted here, in code, and handed
 * to the model already made; the model only reads it. The reading always
 * states our number, so «اگر از محاسبه مطمئن نیستی، عدد نساز» is kept by the
 * one party that is always sure. Like the provider it wraps, this engine
 * fails honestly — a silent or broken upstream ends in a retry, never in
 * canned text.
 */
@Injectable()
export class AbjadReadingProvider implements ReadingProvider {
  constructor(
    private readonly inner: ReadingProvider,
    private readonly flags: FeatureFlagsService,
    private readonly config: AiConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async generate(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
    profile?: ReadingProfileContext,
  ): Promise<GeneratedReading> {
    if (fortune.id !== 'abjad') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(ABJAD_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.abjad.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const abjad = computeAbjad(input.intention);
    if (abjad.total === 0) {
      // Nothing countable to open the fal with; let the ordinary provider
      // answer the silence rather than invent a number from nowhere.
      this.logger.info('reading.abjad.no-input', {});
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const word = (input.intention ?? '').trim();
    const messages = buildAbjadPrompt(word, abjad, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseAbjadReading(content);
        this.logger.info('reading.abjad.succeeded', {
          total: abjad.total,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(word, abjad, parsed, profile?.locale);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof AbjadRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.abjad.retrying', {
          total: abjad.total,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.abjad.failed', {
      total: abjad.total,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new AbjadRequestError('abjad generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildAbjadPrompt>): Promise<string> {
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
          this.logger.error('reading.abjad.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new AbjadRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new AbjadRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof AbjadRequestError) throw error;
      if (controller.signal.aborted) {
        throw new AbjadRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new AbjadRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * Validates the model's half of the reading — five non-empty sections — and
 * caps each so a runaway completion cannot bloat the stored reading. The
 * number is never taken from here; the engine owns it.
 */
export function parseAbjadReading(raw: string): AbjadModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new AbjadRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof AbjadModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new AbjadRequestError(`completion is missing ${key}`, true);
    }
    return text.slice(0, MAX_SECTION_CHARS);
  };

  return {
    numberMeaning: section('numberMeaning'),
    interpretationForIntention: section('interpretationForIntention'),
    hope: section('hope'),
    caution: section('caution'),
    practicalAdvice: section('practicalAdvice'),
  };
}

/**
 * Flattens the schema into the reading text the client already renders: the
 * counted number first — the fal IS the number — then its reading, ending on
 * the same «برای امروز:» promise every other fortune keeps. The working line
 * and the title both carry our number, never the model's.
 */
function composeReading(
  word: string,
  abjad: AbjadResult,
  parsed: AbjadModelReading,
  locale?: string,
): GeneratedReading {
  const advice = labels.stripForToday(parsed.practicalAdvice);
  const total = labels.digits(abjad.total, locale);
  // The letters are Arabic script whatever language reads them — the sum is
  // of this person's own word — so only the sentence around them changes.
  const working = labels.abjadWorking(
    word,
    abjad.letters.length <= MAX_BREAKDOWN_LETTERS
      ? `${renderBreakdown(abjad.letters)} = ${total}`
      : total,
    locale,
  );
  return {
    title: labels.abjadTitle(total, locale),
    reading: [
      working,
      parsed.numberMeaning,
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `${labels.forToday(locale)} ${advice}`,
    ].join('\n\n'),
  };
}
