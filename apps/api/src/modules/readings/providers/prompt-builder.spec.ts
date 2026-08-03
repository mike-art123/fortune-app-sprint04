import { buildPrompt } from './prompt-builder';
import { FORTUNE_CATALOG, findFortune } from '../fortune-catalog';

const hafez = findFortune('hafez')!;
const tarot = findFortune('tarot')!;
const dream = findFortune('dream')!;
const love = findFortune('love')!;

describe('buildPrompt', () => {
  it('returns a system message followed by a user message', () => {
    const messages = buildPrompt(hafez, { intention: 'نیت' });
    expect(messages).toHaveLength(2);
    expect(messages[0].role).toBe('system');
    expect(messages[1].role).toBe('user');
  });

  it('carries the manifesto and the anti-prophecy rules for every fortune', () => {
    for (const fortune of FORTUNE_CATALOG) {
      const [system] = buildPrompt(fortune, {
        intention: 'نیت',
        narration: 'در باغی سبز راه می‌رفتم',
        selfName: 'سارا',
        otherName: 'امیر',
      });
      expect(system.content).toContain('مشخص و جسور بنویس');
      expect(system.content).toContain('تضمین نده');
      expect(system.content).toContain('"title"');
      expect(system.content).toContain('"reading"');
    }
  });

  it('forbids the model from naming the machinery', () => {
    const [system] = buildPrompt(hafez, {});
    expect(system.content).toContain('هرگز از کلمات «هوش مصنوعی»');
  });

  it('frames hafez around the divan and tarot around a card', () => {
    expect(buildPrompt(hafez, {})[0].content).toContain('فال حافظ است');
    expect(buildPrompt(tarot, {})[0].content).toContain('فال تاروت است');
  });

  it('adds the confirmed name as neutralized data (scope §16)', () => {
    const [system] = buildPrompt(hafez, {}, { displayName: 'علی\n«دستور»' });
    expect(system.content).toContain('نام کوچک کاربر برای خطاب: «علیدستور»');
    expect(system.content).toContain('نادیده بگیر');
    expect(system.content).not.toContain('\n«دستور»');
  });

  it('omits the persona block when no name is confirmed', () => {
    const [system] = buildPrompt(hafez, {}, { displayName: null });
    expect(system.content).not.toContain('نام کوچک کاربر');
  });

  it('forbids a compatibility score in the love reading', () => {
    const [system] = buildPrompt(love, { selfName: 'سارا', otherName: 'امیر' });
    expect(system.content).toContain('درصد و نمرهٔ سازگاری');
  });

  it('includes the intention when it is offered', () => {
    const [, user] = buildPrompt(hafez, { intention: 'برای کارم' });
    expect(user.content).toContain('برای کارم');
  });

  it('honours silence instead of treating it as missing input', () => {
    const [, user] = buildPrompt(hafez, {});
    expect(user.content).toContain('در دل نگه داشته');
    expect(user.content).not.toContain('undefined');
  });

  it('passes the dream narration through', () => {
    const [, user] = buildPrompt(dream, { narration: 'در باغی سبز راه می‌رفتم' });
    expect(user.content).toContain('در باغی سبز راه می‌رفتم');
  });

  it('includes both names for the love reading', () => {
    const [, user] = buildPrompt(love, { selfName: 'سارا', otherName: 'امیر' });
    expect(user.content).toContain('سارا');
    expect(user.content).toContain('امیر');
  });

  it('never leaks fields belonging to another input kind', () => {
    const [, user] = buildPrompt(hafez, {
      intention: 'نیت',
      narration: 'خوابِ خصوصی',
      selfName: 'سارا',
    });
    expect(user.content).not.toContain('خوابِ خصوصی');
    expect(user.content).not.toContain('سارا');
  });

  it('produces no undefined or null text for any kind', () => {
    for (const fortune of FORTUNE_CATALOG) {
      const messages = buildPrompt(fortune, {});
      for (const message of messages) {
        expect(message.content).not.toMatch(/undefined|null/);
        expect(message.content.trim().length).toBeGreaterThan(0);
      }
    }
  });
  it('adds the output-language block only for non-Persian locales', () => {
    const fa = buildPrompt(hafez, {}, { displayName: null, locale: 'fa' });
    expect(fa[0].content).not.toContain('For today:');

    const en = buildPrompt(hafez, {}, { displayName: null, locale: 'en' });
    expect(en[0].content).toContain('For today:');
    // The user message closes on the same instruction, in the output
    // language: the last line the model reads before it answers.
    expect(en[1].content).toContain('Answer in English.');
    // The instruction to answer in English is itself in English. Written in
    // Persian it was one more line in a wall of Persian, and the model went
    // on answering in Persian; a change of register is the part it cannot
    // read past.
    expect(en[0].content).toContain('OUTPUT LANGUAGE');
    expect(en[0].content).toContain('in English, and in English only');
    // And it names the keys of the contract it is attached to. The generic
    // contract's two are the default; a raw engine passes its own.
    expect(en[0].content).toContain('"title", "reading"');
  });
});
