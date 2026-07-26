/**
 * Tolerant parse of a JSON object out of model output.
 *
 * Models occasionally wrap their answer in code fences or a friendly sentence;
 * we recover rather than punish the user for it. Shared by every AI call so
 * the recovery rules are identical wherever a model answers us.
 *
 * Throws when nothing usable is present — the caller decides what that means.
 */
export function extractJsonObject(raw: string): Record<string, unknown> {
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
    throw new Error('completion contained no JSON object');
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

  throw new Error('completion was malformed or truncated JSON');
}
