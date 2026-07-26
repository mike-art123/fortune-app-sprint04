import {
  FEELINGS,
  FEELING_FA,
  MAX_PROMPT_CHARS,
  isFeeling,
  isTender,
  promptFor,
  promptFrom,
} from './reflection-feelings';

/**
 * The journal's vocabulary. Two things must hold: every feeling has a Persian
 * word and a line of its own, and the heavier feelings are never probed — not
 * by us, and not by a model.
 */
describe('reflection feelings', () => {
  it('gives every feeling a word and a line', () => {
    for (const feeling of FEELINGS) {
      expect(FEELING_FA[feeling]).not.toHaveLength(0);
      const prompt = promptFor(feeling);
      expect(prompt.text.length).toBeGreaterThan(0);
      expect(prompt.text.length).toBeLessThanOrEqual(MAX_PROMPT_CHARS);
      expect(prompt.feeling).toBe(feeling);
    }
  });

  it('asks the lighter feelings a question and the heavier ones nothing', () => {
    expect(promptFor('calm').tender).toBe(false);
    expect(promptFor('calm').text).toContain('؟');
    expect(promptFor('hopeful').text).toContain('؟');

    expect(promptFor('worried').tender).toBe(true);
    expect(promptFor('heavy').tender).toBe(true);
    // Not a question, and never an instruction to dig further.
    expect(promptFor('worried').text).not.toContain('؟');
    expect(promptFor('heavy').text).not.toContain('؟');
  });

  it('leaves room, and says plainly that a real person is allowed', () => {
    expect(promptFor('heavy').text).toContain('حرف بزن');
    expect(promptFor('worried').text).toContain('کافی است');
  });

  it('knows only the five words it offers', () => {
    expect(isFeeling('calm')).toBe(true);
    expect(isFeeling('devastated')).toBe(false);
    expect(isFeeling('')).toBe(false);
    expect(FEELINGS).toHaveLength(5);
  });

  it('refuses a model answer for a feeling it should never have seen', () => {
    for (const feeling of FEELINGS.filter(isTender)) {
      expect(promptFrom({ question: 'چه چیزی آزارت می‌دهد؟' }, feeling)).toBeNull();
    }
  });

  it('accepts one short Persian question and nothing else', () => {
    expect(promptFrom({ question: 'امروز چه چیزی آرامت کرد؟' }, 'calm')).toBe(
      'امروز چه چیزی آرامت کرد؟',
    );

    for (const bad of [
      { question: 'What made you calm today?' }, // not Persian
      { question: 'امروز آرام بودی.' }, // not a question
      { question: '<b>چطوری؟</b>' }, // markup
      { question: 'ببین https://example.com چطور؟' }, // a link
      { question: '' },
      { question: `${'چ'.repeat(MAX_PROMPT_CHARS + 1)}؟` }, // too long
      {},
    ]) {
      expect(promptFrom(bad, 'calm')).toBeNull();
    }
  });
});
