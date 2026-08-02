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
import { TAROT_DECK, type TarotCard } from './tarot-deck';
import { buildTarotPrompt } from './tarot-prompt';
import { drawCard } from './card-selection';
import * as labels from '../providers/reading-labels';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const TAROT_RAW_ENGINE_FLAG = 'tarot.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;

class TarotRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'TarotRequestError';
  }
}

/** The model's half of the schema; the card and its meaning are ours to draw
 *  and add. */
interface TarotModelReading {
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The tarot raw engine, worn as a decorator over the ordinary provider so
 * nothing outside this folder learns a new name. Every fortune that is not
 * tarot — and tarot itself while the flag is off or no model is configured —
 * passes straight through.
 *
 * When it runs, the stable draw picks today's card and orientation for this
 * intention, the real card and its traditional meaning ride in the prompt, and
 * the reading always states the drawn card, never one the model named. Like
 * the provider it wraps, this engine fails honestly — a silent or broken
 * upstream ends in a retry, never in canned text.
 */
@Injectable()
export class TarotReadingProvider implements ReadingProvider {
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
    if (fortune.id !== 'tarot') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(TAROT_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.tarot.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const { index, reversed } = drawCard({
      dateKey,
      intention: input.intention ?? '',
      deckSize: TAROT_DECK.length,
    });
    const card = TAROT_DECK[index];
    if (!card) {
      // Unreachable — the draw is bounded by the deck length — but the index
      // signature is `T | undefined`, and a raw engine never guesses a card.
      throw new TarotRequestError(`draw fell outside the deck at ${index}`, false);
    }
    const meaning = reversed ? card.reversedFa : card.uprightFa;
    const messages = buildTarotPrompt(card, reversed, meaning, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseTarotReading(content);
        this.logger.info('reading.tarot.succeeded', {
          cardId: card.id,
          reversed,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(card, reversed, meaning, parsed, profile?.locale);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof TarotRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.tarot.retrying', {
          cardId: card.id,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.tarot.failed', {
      cardId: card.id,
      reversed,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new TarotRequestError('tarot generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildTarotPrompt>): Promise<string> {
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
          this.logger.error('reading.tarot.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new TarotRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new TarotRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof TarotRequestError) throw error;
      if (controller.signal.aborted) {
        throw new TarotRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new TarotRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * Validates the model's half of the reading — four non-empty sections — and
 * caps each so a runaway completion cannot bloat the stored reading. The card
 * and its meaning are never taken from here; the deck owns them.
 */
export function parseTarotReading(raw: string): TarotModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new TarotRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof TarotModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new TarotRequestError(`completion is missing ${key}`, true);
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
 * drawn card and its traditional meaning first — the fal IS the card — then
 * its reading, ending on the same «برای امروز:» promise every other fortune
 * keeps. The card name, orientation and meaning are all ours, never the
 * model's.
 */
function composeReading(
  card: TarotCard,
  reversed: boolean,
  meaning: string,
  parsed: TarotModelReading,
  locale?: string,
): GeneratedReading {
  const advice = labels.stripForToday(parsed.practicalAdvice);
  const name = labels.cardName(card, locale);
  return {
    title: labels.tarotTitle(name, reversed, locale),
    reading: [
      `${labels.yourCard(locale)} ${name} — ${labels.orientation(reversed, locale)}`,
      // The deck's traditional meanings exist in Persian only. The model was
      // given them and its paragraphs carry the sense, so a reader who cannot
      // read Persian is not handed a line of it.
      ...(labels.showsPersianSource(locale)
        ? [`${labels.traditionalMeaning(locale)} ${meaning}`]
        : []),
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `${labels.forToday(locale)} ${advice}`,
    ].join('\n\n'),
  };
}
