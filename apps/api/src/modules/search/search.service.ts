import { Injectable } from '@nestjs/common';
import { AiConfig } from '../../config/ai.config';
import { extractJsonObject } from '../../common/json/extract-json-object';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { buildSearchPrompt } from './search-prompt';
import {
  NO_INTERPRETATION,
  interpretationFrom,
  type SearchInterpretation,
} from './search-interpretation';

/** Off by default; turning it on is a deliberate, reversible decision. */
export const AI_BAR_FLAG = 'search.ai-bar';

/** Routing needs a handful of tokens, never a paragraph. */
const MAX_TOKENS = 60;

/**
 * The last stage of the search pipeline (scope §2): a sentence the app's own
 * rules could not place.
 *
 * Everything about this is deliberately small. It answers with an id or with
 * nothing, it costs a few tokens, and it never sees or writes a reading. When
 * the flag is off, the model is unreachable, or the answer is not one we
 * recognise, the result is "nothing" — the app then simply says it did not
 * find anything, which is the same calm ending it already had.
 *
 * The typed question is never logged and never leaves this call.
 */
@Injectable()
export class SearchService {
  constructor(
    private readonly config: AiConfig,
    private readonly flags: FeatureFlagsService,
    private readonly logger: AppLoggerService,
  ) {}

  async interpret(query: string): Promise<SearchInterpretation> {
    const trimmed = query.trim();
    if (trimmed.length === 0) return NO_INTERPRETATION;

    const enabled = await this.flags.isEnabled(AI_BAR_FLAG);
    if (!enabled || !this.config.isConfigured) return NO_INTERPRETATION;

    const startedAt = Date.now();
    try {
      const raw = await this.ask(trimmed);
      const interpretation = interpretationFrom(extractJsonObject(raw));
      this.logger.info('search.ai.answered', {
        kind: interpretation.kind,
        queryLength: trimmed.length,
        durationMs: Date.now() - startedAt,
      });
      return interpretation;
    } catch (error) {
      // A search box must never show an error. Nothing found is a fine answer.
      this.logger.warn('search.ai.unavailable', {
        queryLength: trimmed.length,
        durationMs: Date.now() - startedAt,
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return NO_INTERPRETATION;
    }
  }

  /** One bounded round-trip. No retries: a search box cannot wait twice. */
  private async ask(query: string): Promise<string> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const response = await fetch(`${this.config.baseUrl.replace(/\/+$/, '')}/chat/completions`, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.model,
          temperature: 0,
          max_tokens: MAX_TOKENS,
          response_format: { type: 'json_object' },
          messages: buildSearchPrompt(query),
        }),
      });

      if (!response.ok) {
        throw new Error(`upstream responded ${response.status}`);
      }

      const payload = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const content = payload.choices?.[0]?.message?.content;
      if (!content) throw new Error('upstream returned an empty completion');
      return content;
    } finally {
      clearTimeout(timer);
    }
  }
}
