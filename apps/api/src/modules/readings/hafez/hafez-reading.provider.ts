import { Injectable } from '@nestjs/common';
import type { Ghazal } from '@prisma/client';
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
import { HafezCorpusService } from './hafez-corpus.service';
import { buildHafezPrompt, renderPoem } from './hafez-prompt';
import { selectGhazalNumber } from './ghazal-selection';
import * as labels from '../providers/reading-labels';

/** The switch that brings the raw engine to life. Off means this file is a
 *  pass-through and the catalog behaves exactly as before. */
export const HAFEZ_RAW_ENGINE_FLAG = 'hafez.raw-engine';

const RETRYABLE_STATUS = new Set([408, 429, 500, 502, 503, 504]);
const MISCONFIGURED_STATUS = new Set([400, 401, 403, 404]);

const MAX_SECTION_CHARS = 2200;
const MAX_VERSES = 3;

class HafezRequestError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = 'HafezRequestError';
  }
}

/** The model's half of the schema; ghazalId and poem are ours to add. */
interface HafezModelReading {
  selectedVerses: string[];
  messageOfThePoem: string;
  interpretationForIntention: string;
  hope: string;
  caution: string;
  practicalAdvice: string;
}

/**
 * The Hafez raw engine (docs/hafez-dataset-sourcing.md, steps 3–5), worn as a
 * decorator over the ordinary provider so nothing outside this folder learns
 * a new name. Every fortune that is not Hafez — and Hafez itself while the
 * flag is off or no model is configured — passes straight through.
 *
 * When it runs: the corpus is ensured into the database, the stable selection
 * draws today's ghazal for this intention, the real poem rides in the prompt,
 * and the reply is refused unless every quoted verse is found in that poem,
 * word for word. Like the provider it wraps, this engine fails honestly —
 * a wrong ghazal, an invented verse or a silent upstream all end in a retry,
 * never in canned text.
 */
@Injectable()
export class HafezReadingProvider implements ReadingProvider {
  constructor(
    private readonly inner: ReadingProvider,
    private readonly corpus: HafezCorpusService,
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
    if (fortune.id !== 'hafez') {
      return this.inner.generate(fortune, input, profile);
    }
    if (!(await this.flags.isEnabled(HAFEZ_RAW_ENGINE_FLAG))) {
      return this.inner.generate(fortune, input, profile);
    }
    if (!this.config.isConfigured) {
      this.logger.warn('reading.hafez.unconfigured', {
        reason: 'flag is on but no model is configured — falling back to the ordinary provider',
      });
      return this.inner.generate(fortune, input, profile);
    }

    const startedAt = Date.now();
    const { edition, count } = await this.corpus.ensureImported();
    const dateKey = dateKeyFor(new Date(), this.monetization.appTimezone);
    const number = selectGhazalNumber({
      edition,
      dateKey,
      intention: input.intention ?? '',
      count,
    });
    const ghazal = await this.corpus.getGhazal(edition, number);
    const poem = renderPoem(ghazal);
    const messages = buildHafezPrompt(ghazal, poem, input, profile);

    const maxAttempts = this.config.maxRetries + 1;
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const content = await this.requestOnce(messages);
        const parsed = parseHafezReading(content, ghazal);
        this.logger.info('reading.hafez.succeeded', {
          edition,
          number,
          attempt,
          durationMs: Date.now() - startedAt,
        });
        return composeReading(ghazal, poem, parsed, profile?.locale);
      } catch (error) {
        lastError = error;
        const retryable = error instanceof HafezRequestError && error.retryable;
        if (!retryable || attempt === maxAttempts) break;
        this.logger.warn('reading.hafez.retrying', {
          number,
          attempt,
          reason: error instanceof Error ? error.name : 'unknown',
        });
      }
    }

    this.logger.error('reading.hafez.failed', {
      edition,
      number,
      model: this.config.model,
      attempts: maxAttempts,
      durationMs: Date.now() - startedAt,
      reason: lastError instanceof Error ? lastError.message : 'unknown',
    });

    throw lastError instanceof Error
      ? lastError
      : new HafezRequestError('hafez generation failed for an unknown reason', false);
  }

  /**
   * One bounded round-trip. Mirrors the transport in `ai-reading.provider` on
   * purpose; the FortuneAIConfig registry (phase 2) is where the two unify.
   */
  private async requestOnce(messages: ReturnType<typeof buildHafezPrompt>): Promise<string> {
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
          this.logger.error('reading.hafez.misconfigured', {
            status: response.status,
            model: this.config.model,
          });
        }
        throw new HafezRequestError(
          `upstream responded ${response.status}`,
          RETRYABLE_STATUS.has(response.status),
        );
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) {
        throw new HafezRequestError('upstream returned an empty completion', true);
      }
      return content;
    } catch (error) {
      if (error instanceof HafezRequestError) throw error;
      if (controller.signal.aborted) {
        throw new HafezRequestError(`timed out after ${this.config.timeoutMs}ms`, true);
      }
      throw new HafezRequestError(error instanceof Error ? error.message : 'network failure', true);
    } finally {
      clearTimeout(timer);
    }
  }
}

/** Comparison fold: quoting is judged on letters, not on spacing habits. */
function foldForMatch(text: string): string {
  return text.replace(/[‌\s]+/g, '');
}

/**
 * Refuses any reply whose quoted verses are not in the given ghazal. A verse
 * that matches after folding is replaced by the canonical text from the
 * corpus, so what reaches the reader is always the Divan's own spelling —
 * «بیت جعلی نساز», enforced in code rather than requested in prose.
 */
export function parseHafezReading(raw: string, ghazal: Ghazal): HafezModelReading {
  let object: Record<string, unknown>;
  try {
    object = extractJsonObject(raw);
  } catch (error) {
    throw new HafezRequestError(
      error instanceof Error ? error.message : 'completion was not JSON',
      true,
    );
  }

  const section = (key: keyof HafezModelReading): string => {
    const value = object[key];
    const text = typeof value === 'string' ? value.trim() : '';
    if (!text) {
      throw new HafezRequestError(`completion is missing ${key}`, true);
    }
    return text.slice(0, MAX_SECTION_CHARS);
  };

  const rawVerses = object.selectedVerses;
  if (!Array.isArray(rawVerses) || rawVerses.length === 0) {
    throw new HafezRequestError('completion carries no selected verses', true);
  }

  const couplets = (JSON.parse(ghazal.verses) as [string, string][]).map(
    ([first, second]) => `${first}\n${second}`,
  );
  const hemistichs = couplets.flatMap((couplet) => couplet.split('\n'));
  const canonical = new Map<string, string>();
  for (const line of [...couplets, ...hemistichs]) {
    canonical.set(foldForMatch(line), line);
  }

  const selectedVerses = rawVerses.slice(0, MAX_VERSES).map((verse) => {
    const text = typeof verse === 'string' ? verse.trim() : '';
    const match = canonical.get(foldForMatch(text));
    if (!match) {
      throw new HafezRequestError('completion quoted a verse that is not in the ghazal', true);
    }
    return match;
  });

  return {
    selectedVerses,
    messageOfThePoem: section('messageOfThePoem'),
    interpretationForIntention: section('interpretationForIntention'),
    hope: section('hope'),
    caution: section('caution'),
    practicalAdvice: section('practicalAdvice'),
  };
}

const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';


/**
 * Flattens the schema into the reading text the client already renders: the
 * whole ghazal first — the fal IS the poem — then the reading of it, ending
 * on the same «برای امروز:» promise every other fortune keeps. The structured
 * fields stay validated here so the client can start rendering them as parts
 * when its own Hafez surface lands.
 */
function composeReading(
  ghazal: Ghazal,
  poem: string,
  parsed: HafezModelReading,
  locale?: string,
): GeneratedReading {
  const advice = labels.stripForToday(parsed.practicalAdvice);
  return {
    // The ghazal itself stays Persian in every language — it is the source,
    // and the prompt keeps it so and translates alongside it.
    title: labels.hafezTitle(ghazal.number, locale),
    reading: [
      poem,
      parsed.messageOfThePoem,
      parsed.interpretationForIntention,
      parsed.hope,
      parsed.caution,
      `${labels.forToday(locale)} ${advice}`,
    ].join('\n\n'),
  };
}
