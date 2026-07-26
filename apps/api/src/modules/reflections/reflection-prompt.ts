import type { PromptMessage } from '../../common/ai/prompt-message';
import { FEELING_FA, MAX_PROMPT_CHARS, type Feeling } from './reflection-feelings';

/**
 * The model's entire input is one word from a list of five (scope §8).
 *
 * It never sees the note, the reading, a name, or anything else. There is
 * nothing here that could leak, because there is nothing here — which is the
 * point: the private text stays in its table and the model only helps phrase a
 * gentler question than the one we wrote.
 */
export function buildReflectionPrompt(feeling: Feeling): PromptMessage[] {
  return [
    {
      role: 'system',
      content: [
        'You write one short Persian question that helps somebody reflect',
        'after a fortune reading. Answer with JSON only:',
        '{"question":"<Persian question>"}',
        '',
        'Rules:',
        '- One question, ending in «؟».',
        `- At most ${MAX_PROMPT_CHARS} characters.`,
        '- Warm, calm, second person singular.',
        '- Never predict, never advise, never diagnose.',
        '- Never ask about anybody else, and never ask for private details',
        '  such as a name, an age, a place, or health.',
        '- The word below is the whole input; you know nothing else.',
      ].join('\n'),
    },
    { role: 'user', content: `FEELING: ${FEELING_FA[feeling]}` },
  ];
}
