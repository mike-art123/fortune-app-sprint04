import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Typed AI provider configuration. Keys never leave the server (doc 06/56). */
@Injectable()
export class AiConfig {
  constructor(private readonly config: ConfigService) {}

  get baseUrl(): string {
    return this.config.get<string>('LLM_BASE_URL') ?? '';
  }
  get apiKey(): string {
    return this.config.get<string>('LLM_API_KEY') ?? '';
  }
  get model(): string {
    return this.config.get<string>('LLM_MODEL') ?? 'gpt-4o-mini';
  }
  get timeoutMs(): number {
    return this.config.get<number>('LLM_TIMEOUT_MS') ?? 20000;
  }
  get maxRetries(): number {
    return this.config.get<number>('LLM_MAX_RETRIES') ?? 1;
  }
  /** AI is enabled only when a base URL and key are configured. */
  get isConfigured(): boolean {
    return this.baseUrl.length > 0 && this.apiKey.length > 0;
  }
}
