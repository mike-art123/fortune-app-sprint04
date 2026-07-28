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
import { computeTasbih, toPersianDigits, type TasbihReading } from './tasbih-count';
import { buildTasbihPrompt } from './tasbih-prompt';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const TASBIH_RAW_ENGINE_FLAG = 'tasbih.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;

const HUMILITY_NOTE =
  'یادآوری: استخاره طلبِ خیر از خداوند است، نه حکمِ حتمی؛ تصمیمِ نهایی با تدبیر و مشورتِ توست.';

class TasbihRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'TasbihRequestError';
  }
}

/** The model's half of the schema; the outcome is ours to count and add. */
interface TasbihModelReading {
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The tasbih istikhara raw engine, worn as a decorator over the ordinary
 * provider so nothing outside this folder learns a new name. Every fortune
 * that is not tasbih — and tasbih itself while the flag is off or no model is
 * configured — passes straight through.
 *
 * When it runs, the outcome (خوب / متوسط / صبر) is counted here, in code, and
 * handed to the model already decided; the model only reads it, gently. The
 * reading always states our outcome and always keeps the humility of istikhara
 * — طلبِ خیر, never a verdict. Like the provider it wraps, this engine fails
 * honestly — a silent or broken upstream ends in a retry, never in canned text.
 */
@Injectable()
export class TasbihReadingProvider implements ReadingProvider {
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
    if (fortune.id !== 'tasbih') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(TASBIH_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.tasbih.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const reading = computeTasbih(dateKey, input.intention ?? '');
    const messages = buildTasbihPrompt(reading.result, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseTasbihReading(content);
        this.logger.info('reading.tasbih.succeeded', {
          result: reading.result,
          beads: reading.beads,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(reading, parsed);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof TasbihRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.tasbih.retrying', {
          result: reading.result,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.tasbih.failed', {
      result: reading.result,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new TasbihRequestError('tasbih generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildTasbihPrompt>): Promise<string> {
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
          this.logger.error('reading.tasbih.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new TasbihRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new TasbihRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof TasbihRequestError) throw error;
      if (controller.signal.aborted) {
        throw new TasbihRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new TasbihRequestError(
        error instanceof Error ? error.message : 'network failure',
        true,
      );
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * Validates the model's half of the reading — four non-empty sections — and
 * caps each so a runaway completion cannot bloat the stored reading. The
 * outcome is never taken from here; the count owns it.
 */
export function parseTasbihReading(raw: string): TasbihModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new TasbihRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof TasbihModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new TasbihRequestError(`completion is missing ${key}`, true);
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
 * counted beads and the outcome first — the fal IS the outcome — then its
 * reading, the «برای امروز:» promise, and finally the humility note that keeps
 * istikhara what it is. The outcome is ours, never the model's.
 */
function composeReading(reading: TasbihReading, parsed: TasbihModelReading): GeneratedReading {
  const advice = parsed.practicalAdvice.replace(/^برای امروز:\s*/, '');
  const beads = toPersianDigits(reading.beads);
  return {
    title: `فال تسبیح — ${reading.result}`,
    reading: [
      `شمارشِ دانه‌ها: ${beads} دانه — نتیجه: ${reading.result}`,
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `برای امروز: ${advice}`,
      HUMILITY_NOTE,
    ].join('\n\n'),
  };
}
