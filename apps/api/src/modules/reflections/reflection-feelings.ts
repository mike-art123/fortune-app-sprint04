/**
 * The reflection journal's vocabulary and its follow-up questions (scope §8).
 *
 * Two decisions shape this whole file, and both are about the note nobody else
 * should read.
 *
 * First: a follow-up question is chosen from the **feeling** alone. The feeling
 * is one of five words the app itself offers, so nothing anybody typed is ever
 * involved in deciding what to ask next.
 *
 * Second: the heavier feelings are not probed. Asking someone who chose
 * «گرفته» to dig further is the wrong instinct; they are met with a sentence
 * that makes room instead, and with the plain fact that talking to a real
 * person is allowed. No text is scanned to decide this, because scanning
 * someone's diary to guess at their state is not care — the app simply behaves
 * gently on the path they chose themselves.
 */

export const FEELINGS = ['calm', 'hopeful', 'longing', 'worried', 'heavy'] as const;
export type Feeling = (typeof FEELINGS)[number];

export const FEELING_FA: Record<Feeling, string> = {
  calm: 'آرام',
  hopeful: 'امیدوار',
  longing: 'دل‌تنگ',
  worried: 'نگران',
  heavy: 'گرفته',
};

/** Feelings the app answers with room rather than a further question. */
export const TENDER_FEELINGS: readonly Feeling[] = ['worried', 'heavy'];

export function isFeeling(value: string): value is Feeling {
  return (FEELINGS as readonly string[]).includes(value);
}

export function isTender(feeling: Feeling): boolean {
  return TENDER_FEELINGS.includes(feeling);
}

/**
 * One short line to sit under the note. For the lighter feelings it is a
 * question; for the heavier ones it is not — it is an acknowledgement, and it
 * never asks for more.
 */
const PROMPT_FA: Record<Feeling, string> = {
  calm: 'اگر بخواهی این آرامش را نگه داری، از چه چیزی مراقبت می‌کنی؟',
  hopeful: 'کوچک‌ترین قدمی که این امید را واقعی می‌کند چیست؟',
  longing: 'دل‌تنگیِ امروزت برای چه چیزی است؟ همان‌جا بنویسش، برای خودت.',
  worried: 'لازم نیست همه‌اش را همین حالا حل کنی. همین که نوشتی، کافی است.',
  heavy: 'روزهای سنگین هم می‌گذرند. اگر بخواهی، با کسی که دوستش داری حرف بزن.',
};

export interface ReflectionPrompt {
  feeling: Feeling;
  /** The line to show. Persian, short, and never a diagnosis. */
  text: string;
  /** True when this is an acknowledgement rather than a question. */
  tender: boolean;
}

/** The prompt the app can always show, with no model involved. */
export function promptFor(feeling: Feeling): ReflectionPrompt {
  return { feeling, text: PROMPT_FA[feeling], tender: isTender(feeling) };
}

/**
 * Validates a model-written question. It must be short Persian prose with no
 * links or markup, and it must be a question — anything else falls back to the
 * written line above, which is never a worse answer, only a plainer one.
 */
export const MAX_PROMPT_CHARS = 120;

export function promptFrom(object: Record<string, unknown>, feeling: Feeling): string | null {
  // A tender feeling is never handed to a model, so an answer for one is
  // discarded even if it arrives.
  if (isTender(feeling)) return null;

  const raw = typeof object.question === 'string' ? object.question : '';
  const text = raw.replace(/\s+/g, ' ').trim();
  if (text.length === 0 || text.length > MAX_PROMPT_CHARS) return null;
  if (/[<>{}`]|https?:\/\//i.test(text)) return null;
  if (!/[؀-ۿ]/.test(text)) return null;
  if (!text.includes('؟')) return null;
  return text;
}
