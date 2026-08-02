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
import { CARDS_DECK, type PlayingCard } from './cards-deck';
import { buildCardsPrompt } from './cards-prompt';
import { drawPlayingCard } from './cards-selection';
import * as labels from '../providers/reading-labels';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const CARDS_RAW_ENGINE_FLAG = 'cards.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;

class CardsRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'CardsRequestError';
  }
}

/** The model's half of the schema; the card and its meaning are ours to draw
 *  and add. */
interface CardsModelReading {
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The playing-card raw engine, worn as a decorator over the ordinary provider
 * so nothing outside this folder learns a new name. Every fortune that is not
 * cards — and cards itself while the flag is off or no model is configured —
 * passes straight through.
 *
 * When it runs, the stable draw picks today's card for this intention, the
 * real card and its traditional meaning ride in the prompt, and the reading
 * always states the drawn card, never one the model named. Like the provider
 * it wraps, this engine fails honestly — a silent or broken upstream ends in a
 * retry, never in canned text.
 */
@Injectable()
export class CardsReadingProvider implements ReadingProvider {
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
    if (fortune.id !== 'cards') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(CARDS_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.cards.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const index = drawPlayingCard({
      dateKey,
      intention: input.intention ?? '',
      deckSize: CARDS_DECK.length,
    });
    const card = CARDS_DECK[index];
    if (!card) {
      // Unreachable — the draw is bounded by the deck length — but the index
      // signature is `T | undefined`, and a raw engine never guesses a card.
      throw new CardsRequestError(`draw fell outside the deck at ${index}`, false);
    }
    const messages = buildCardsPrompt(card, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseCardsReading(content);
        this.logger.info('reading.cards.succeeded', {
          cardId: card.id,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(card, parsed, profile?.locale);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof CardsRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.cards.retrying', {
          cardId: card.id,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.cards.failed', {
      cardId: card.id,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new CardsRequestError('cards generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildCardsPrompt>): Promise<string> {
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
          this.logger.error('reading.cards.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new CardsRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new CardsRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof CardsRequestError) throw error;
      if (controller.signal.aborted) {
        throw new CardsRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new CardsRequestError(error instanceof Error ? error.message : 'network failure', true);
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
export function parseCardsReading(raw: string): CardsModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new CardsRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof CardsModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new CardsRequestError(`completion is missing ${key}`, true);
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
 * keeps. The card name and meaning are ours, never the model's.
 */
function composeReading(
  card: PlayingCard,
  parsed: CardsModelReading,
  locale?: string,
): GeneratedReading {
  const advice = labels.stripForToday(parsed.practicalAdvice);
  const name = labels.cardName(card, locale);
  return {
    title: labels.cardsTitle(name, locale),
    reading: [
      `${labels.yourCard(locale)} ${name}`,
      ...(labels.showsPersianSource(locale)
        ? [`${labels.traditionalMeaning(locale)} ${card.meaningFa}`]
        : []),
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `${labels.forToday(locale)} ${advice}`,
    ].join('\n\n'),
  };
}
