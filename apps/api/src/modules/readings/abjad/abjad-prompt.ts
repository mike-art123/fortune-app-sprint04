import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import { VOICE, personaFor } from '../providers/prompt-builder';
import { toPersianDigits, type AbjadResult } from './abjad-numerology';

/**
 * The abjad raw engine's prompt. The number is already counted — «اگر از
 * محاسبه مطمئن نیستی، عدد نساز» is kept by never asking the model to add.
 * Its job narrows to reading the given number in the abjad tradition and
 * tying it to the user's intention; the reading itself states the real
 * number, so the model never has to be trusted with the arithmetic.
 */

const ABJAD_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"numberMeaning":"معنای کلیِ این عدد در سنتِ ابجد، یک بند",',
  '"interpretationForIntention":"پیوندِ عدد با نیتِ کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این عدد در یک بند",',
  '"caution":"هشدارِ ملایمِ این عدد در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'عددِ ابجد از پیش و درست محاسبه شده و در پیام آمده است؛ عددِ دیگری نساز',
  'و در متن عددی جز همین نیاور. اگر عدد را بازمی‌گویی، دقیقاً همین عدد باشد.',
].join('\n');

const ABJAD_FRAMING = [
  'فال ابجد است و حسابِ ابجدِ کبیرِ نام یا نیتِ کاربر از پیش انجام شده و',
  'عددش در ادامه آمده است. کارِ تو خواندنِ همین عدد است در سنتِ ابجد و',
  'گره‌زدنش به نیتِ کاربر — با احترام، بی‌قضاوت و بدونِ حکمِ قطعی.',
].join('\n');

export function buildAbjadPrompt(
  word: string,
  abjad: AbjadResult,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const system = [VOICE, '', ABJAD_FRAMING, '', ABJAD_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .join('\n');

  const total = toPersianDigits(abjad.total);
  const user = [
    `نام یا نیتِ کاربر: «${word}»`,
    `حسابِ ابجدِ کبیر: عددِ ${total}.`,
    'حالا همین عدد را برای این نیت بخوان.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
