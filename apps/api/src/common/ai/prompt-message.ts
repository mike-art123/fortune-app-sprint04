/**
 * One message in a chat completion. Every prompt this server builds — the
 * reading itself, search routing, the history summary — is a list of these,
 * so the shape is written once and imported everywhere rather than redeclared
 * per feature.
 */
export interface PromptMessage {
  role: 'system' | 'user';
  content: string;
}
