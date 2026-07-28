import { Injectable } from '@nestjs/common';
import { AiConfig } from '../../../config/ai.config';
import { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type {
  GeneratedReading,
  ReadingProfileContext,
  ReadingProvider,
} from './reading-provider.interface';
import { buildPrompt } from './prompt-builder';
import { extractJsonObject } from '../../../common/json/extract-json-object';

/** Statuses worth a second attempt. Everything else fails fast. */
const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);

/**
 * Statuses that mean *we* are wrong, not the weather: a bad key, a bad base
 * URL, or a model id that does not exist. These get their own loud log line,
 * because the one that actually happened — `LLM_MODEL=gbt_40_mini` — was
 * invisible for as long as a fallback was quietly answering in its place.
 */
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

/** Guards against a model that ignores the length contract. */
const MAX_TITLE_CHARS = 80;
const MAX_READING_CHARS = 7000;
const MIN_READING_CHARS = 40;

class AiRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'AiRequestError';
  }
}

/**
 * Real generation against an OpenAI-compatible endpoint (doc 56).
 *
 * This provider fails. That is the design. It used to "degrade gracefully" by
 * answering with a canned mock reading, which sounds kind and was in fact the
 * whole bug: a mistyped model id meant every request 404'd, every 404 became
 * the same three paragraphs, and thirty-eight different fortunes returned one
 * text — with HTTP 200 on it, so nobody could see anything was wrong.
 *
 * A reading that is not this person's reading is worth less than an honest
 * "دوباره تلاش کن". `ReadingsService` already turns a throw here into exactly
 * that, and gives back the rewarded-ad entitlement while it does.
 *
 * The offering text is never logged — only shapes, timings and outcomes.
 */
@Injectable()
export class AiReadingProvider implements ReadingProvider {
  constructor(
    private readonly config: AiConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async generate(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
    profile?: ReadingProfileContext,
  ): Promise<GeneratedReading> {
    const startedAt = Date.now();
    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const generated = await this.requestOnce(fortune, input, profile);
        this.logger.info('reading.ai.succeeded', {
          fortuneId: fortune.id,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return generated;
      } catch (error) {
        lastError = error;
        const retryable = error instanceof AiRequestError && error.retryable;

        if (!retryable || attempt === maxAttempts) break;

        this.logger.warn('reading.ai.retrying', {
          fortuneId: fortune.id,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    // Error, not warn, and the model id is in it: a failure nobody can see is
    // how one typo survived in production.
    this.logger.error('reading.ai.failed', {
      fortuneId: fortune.id,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new AiRequestError('generation failed for an unknown reason', false);
  }

  /** One HTTP round-trip, bounded by a hard deadline. */
  private async requestOnce(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
    profile?: ReadingProfileContext,
  ): Promise<GeneratedReading> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const response = await fetch(`${this.baseUrl()}/chat/completions`, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.model,
          temperature: 0.85,
          max_tokens: 2400,
          response_format: { type: 'json_object' },
          messages: withImage(buildPrompt(fortune, input, profile), fortune, input),
        }),
      });

      if (!response.ok) {
        if (MISCONFIGURED_STATUS.has(response.status)) {
          this.logger.error('reading.ai.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new AiRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };

      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new AiRequestError('upstream returned an empty completion', true);
      }

      return parseGeneratedReading(content);
    } catch (error) {
      if (error instanceof AiRequestError) throw error;
      if (controller.signal.aborted) {
        throw new AiRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new AiRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }

  private baseUrl(): string {
    return this.config.baseUrl.replace(/\/+$/, '');
  }
}

/**
 * Coffee is the one fortune the model must SEE. When a cup photo is offered,
 * the user turn becomes a multimodal message — the text prompt plus the image
 * inline — exactly the shape an OpenAI-compatible vision endpoint expects.
 * Every other fortune passes straight through, so the wire shape and all the
 * existing behaviour stay identical for text readings.
 *
 * The result is serialized straight into the request body, so a plain array is
 * enough here. The image rides through and is never logged or stored (§16).
 */
function withImage(
  messages: PromptMessage[],
  fortune: FortuneCatalogEntry,
  input: ReadingInputDto,
): unknown[] {
  const image = input.imageDataUrl;
  if (fortune.inputKind !== 'photo' || !image) return messages;
  return messages.map((message) => {
    if (message.role !== 'user') return message;
    return {
      role: 'user',
      content: [
        { type: 'text', text: message.content },
        { type: 'image_url', image_url: { url: image } },
      ],
    };
  });
}

/**
 * Tolerant parse of the model's JSON. Models occasionally add fences or prose;
 * we recover rather than punish the user for it — but we refuse anything that
 * does not carry a usable title and body.
 */
export function parseGeneratedReading(raw: string): GeneratedReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new AiRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const title = typeof object.title === 'string' ? object.title.trim() : '';
  const reading = typeof object.reading === 'string' ? object.reading.trim() : '';

  if (!title || reading.length < MIN_READING_CHARS) {
    throw new AiRequestError('completion did not match the output contract', true);
  }

  return {
    title: title.slice(0, MAX_TITLE_CHARS),
    reading: reading.slice(0, MAX_READING_CHARS),
  };
}
