import type { Ghazal } from '@prisma/client';
import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import { VOICE, languageDirective, personaFor } from '../providers/prompt-builder';

/**
 * The Hafez raw engine's prompt (docs/hafez-dataset-sourcing.md, steps 4–5).
 *
 * This is the moment «بیت جعلی نساز» finally has something true to protect:
 * the real ghazal is in the prompt, drawn by the stable selection, and the
 * model's job narrows from inventing a poem to reading one. The voice rule
 * against fabricating verses still stands — the model may only quote from
 * the text given here, and the parser refuses anything it cannot find in the
 * poem, word for word.
 */

/** Renders the stored couplets as readable text: hemistichs paired, couplets
 *  separated by a blank line — the shape a reader expects a ghazal in. */
export function renderPoem(ghazal: Ghazal): string {
  const couplets = JSON.parse(ghazal.verses) as [string, string][];
  return couplets.map(([first, second]) => `${first}\n${second}`).join('\n\n');
}

const HAFEZ_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"selectedVerses":["یک تا سه بیت، هر بیت دو مصراع با \\n بینشان"],',
  '"messageOfThePoem":"پیام کلی غزل در یک بند",',
  '"interpretationForIntention":"پیوند غزل با نیت کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این غزل در یک بند",',
  '"caution":"هشدارِ ملایم غزل در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'دربارهٔ selectedVerses: فقط بیت‌هایی از همین غزل که در ادامه می‌آید،',
  'کلمه‌به‌کلمه و بدون هیچ تغییری. بیتی از خودت نساز و از غزل دیگری نیاور.',
  'بیت‌هایی را انتخاب کن که به نیت کاربر نزدیک‌ترند.',
].join('\n');

const HAFEZ_FRAMING = [
  'فال حافظ است و غزلِ واقعیِ تفأل در ادامهٔ همین پیام آمده است.',
  'کار تو خواندنِ همین غزل برای نیتِ کاربر است: به زبان و تصویرِ دیوان —',
  'می و ساقی و رند و صبا و گل — و با احترام به متنِ خودِ حافظ.',
  'تفسیر باید از بیت‌های همین غزل برخیزد، نه از حافظه یا غزلی دیگر.',
].join('\n');

export function buildHafezPrompt(
  ghazal: Ghazal,
  poem: string,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const language = languageDirective(profile?.locale);
  const system = [VOICE, '', HAFEZ_FRAMING, '', HAFEZ_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .concat(language ? ['', language] : [])
    .join('\n');

  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const user = [
    `غزل شمارهٔ ${ghazal.number} دیوان حافظ:`,
    poem,
    offering,
    'حالا همین غزل را برای این نیت بخوان.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
