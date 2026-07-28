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
import { RUNE_DECK, type RuneCard } from './rune-deck';
import { buildRunePrompt } from './rune-prompt';
import { drawRune } from './rune-selection';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const RUNE_RAW_ENGINE_FLAG = 'rune.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;

class RuneRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'RuneRequestError';
  }
}

/** The model's half of the schema; the rune and its meaning are ours to draw
 *  and add. */
interface RuneModelReading {
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The rune raw engine, worn as a decorator over the ordinary provider so
 * nothing outside this folder learns a new name. Every fortune that is not
 * rune — and rune itself while the flag is off or no model is configured —
 * passes straight through.
 *
 * When it runs, the stable draw picks today's rune for this intention, the
 * real rune and its traditional meaning ride in the prompt, and the reading
 * always states the drawn rune, never one the model named. Like the provider
 * it wraps, this engine fails honestly — a silent or broken upstream ends in a
 * retry, never in canned text.
 */
@Injectable()
export class RuneReadingProvider implements ReadingProvider {
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
    if (fortune.id !== 'rune') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(RUNE_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.rune.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const index = drawRune({
      dateKey,
      intention: input.intention ?? '',
      deckSize: RUNE_DECK.length,
    });
    const rune = RUNE_DECK[index];
    if (!rune) {
      // Unreachable — the draw is bounded by the set length — but the index
      // signature is `T | undefined`, and a raw engine never guesses a rune.
      throw new RuneRequestError(`draw fell outside the futhark at ${index}`, false);
    }
    const messages = buildRunePrompt(rune, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseRuneReading(content);
        this.logger.info('reading.rune.succeeded', {
          runeId: rune.id,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(rune, parsed);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof RuneRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.rune.retrying', {
          runeId: rune.id,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.rune.failed', {
      runeId: rune.id,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new RuneRequestError('rune generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildRunePrompt>): Promise<string> {
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
          this.logger.error('reading.rune.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new RuneRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new RuneRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof RuneRequestError) throw error;
      if (controller.signal.aborted) {
        throw new RuneRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new RuneRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * Validates the model's half of the reading — four non-empty sections — and
 * caps each so a runaway completion cannot bloat the stored reading. The rune
 * and its meaning are never taken from here; the set owns them.
 */
export function parseRuneReading(raw: string): RuneModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new RuneRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof RuneModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new RuneRequestError(`completion is missing ${key}`, true);
    }
    return text.slice(0, MAX_SECTION_CHARS);
  };

  return {
    interpretationForIntention: section('interpretationForIntention'),
    hope: section('hope'),
    caution: section('caution'),
    practicalAdvice: section('practicalAdvice'),
  };
}

/**
 * Flattens the schema into the reading text the client already renders: the
 * drawn rune and its traditional meaning first — the fal IS the rune — then
 * its reading, ending on the same «برای امروز:» promise every other fortune
 * keeps. The rune name and meaning are ours, never the model's.
 */
function composeReading(rune: RuneCard, parsed: RuneModelReading): GeneratedReading {
  const advice = parsed.practicalAdvice.replace(/^برای امروز:\s*/, '');
  return {
    title: `رون — ${rune.nameFa}`,
    reading: [
      `رونِ تو: ${rune.nameFa} (${rune.nameEn})`,
      `معنای سنتی: ${rune.meaningFa}`,
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `برای امروز: ${advice}`,
    ].join('\n\n'),
  };
}
