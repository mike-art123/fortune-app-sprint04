import { Injectable } from '@nestjs/common';
import { AiConfig } from '../../../config/ai.config';
import { AppLoggerService } from '../../../infrastructure/logging/app-logger.service';
import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { GeneratedReading, ReadingProvider } from './reading-provider.interface';
import { MockReadingProvider } from './mock-reading.provider';
import { buildPrompt } from './prompt-builder';

/** Statuses worth a second attempt. Everything else fails fast. */
const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);

/** Guards against a model that ignores the length contract. */
const MAX_TITLE_CHARS = 80;
const MAX_READING_CHARS = 4000;
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
 * Degrades gracefully by design: if the model is unreachable, slow, or returns
 * something we cannot trust, the user still receives the calm mock reading
 * rather than an error screen. The fallback is logged, never surfaced.
 *
 * The offering text is never logged — only shapes, timings and outcomes.
 */
@Injectable()
export class AiReadingProvider implements ReadingProvider {
  constructor(
    private readonly config: AiConfig,
    private readonly fallback: MockReadingProvider,
    private readonly logger: AppLoggerService,
  ) {}

  async generate(fortune: FortuneCatalogEntry, input: ReadingInputDto): Promise<GeneratedReading> {
    const startedAt = Date.now();
    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const generated = await this.requestOnce(fortune, input);
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

    this.logger.warn('reading.ai.fell_back_to_mock', {
      fortuneId: fortune.id,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    return this.fallback.generate(fortune, input);
  }

  /** One HTTP round-trip, bounded by a hard deadline. */
  private async requestOnce(
    fortune: FortuneCatalogEntry,
    input: ReadingInputDto,
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
          max_tokens: 900,
          response_format: { type: 'json_object' },
          messages: buildPrompt(fortune, input),
        }),
      });

      if (!response.ok) {
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
 * Tolerant parse of the model's JSON. Models occasionally add fences or prose;
 * we recover rather than punish the user for it — but we refuse anything that
 * does not carry a usable title and body.
 */
export function parseGeneratedReading(raw: string): GeneratedReading {
  const object = extractJsonObject(raw);

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

/** Parses the first balanced JSON object in the text, ignoring braces in strings. */
function extractJsonObject(raw: string): Record<string, unknown> {
  const text = raw
    .trim()
    .replace(/^```(?:json)?/i, '')
    .replace(/```$/, '')
    .trim();

  const attempt = (candidate: string): Record<string, unknown> | null => {
    try {
      const parsed: unknown = JSON.parse(candidate);
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? (parsed as Record<string, unknown>)
        : null;
    } catch {
      return null;
    }
  };

  const direct = attempt(text);
  if (direct) return direct;

  const start = text.indexOf('{');
  if (start === -1) {
    throw new AiRequestError('completion contained no JSON object', true);
  }

  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let i = start; i < text.length; i++) {
    const char = text[i];

    if (inString) {
      if (escaped) escaped = false;
      else if (char === '\\') escaped = true;
      else if (char === '"') inString = false;
      continue;
    }

    if (char === '"') inString = true;
    else if (char === '{') depth++;
    else if (char === '}') {
      depth--;
      if (depth === 0) {
        const scanned = attempt(text.slice(start, i + 1));
        if (scanned) return scanned;
        break;
      }
    }
  }

  throw new AiRequestError('completion was malformed or truncated JSON', true);
}
