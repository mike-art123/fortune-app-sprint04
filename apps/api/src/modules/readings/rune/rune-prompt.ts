import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import { VOICE, personaFor } from '../providers/prompt-builder';
import type { RuneCard } from './rune-deck';

/**
 * The rune raw engine's prompt. The rune is already drawn from the real futhark
 * and its traditional meaning is handed over here, so «رونِ ساختگی نساز» is kept
 * by the set, not asked of the model. The model's job narrows to reading this
 * one real rune for the user's intention.
 */

const RUNE_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"interpretationForIntention":"پیوندِ این رون با نیتِ کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این رون در یک بند",',
  '"caution":"هشدارِ ملایمِ این رون در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'فقط دربارهٔ همین رون بنویس. رونِ دیگری نام نبر و معنایی خارج از سنتِ',
  'همین رون به آن نبند.',
].join('\n');

const RUNE_FRAMING = [
  'فال رون است و رونِ واقعیِ کشیده‌شده و معنای سنتی‌اش در ادامه آمده است.',
  'کارِ تو خواندنِ همین رون برای نیتِ کاربر است — با احترام به معنای سنتی،',
  'بی‌قضاوت و بدونِ حکمِ قطعی. تفسیر باید از همین رون برخیزد نه از رونی دیگر.',
].join('\n');

export function buildRunePrompt(
  rune: RuneCard,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const system = [VOICE, '', RUNE_FRAMING, '', RUNE_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .join('\n');

  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const user = [
    `رونِ کشیده‌شده: «${rune.nameFa}» (${rune.nameEn}).`,
    `معنای سنتیِ این رون: ${rune.meaningFa}`,
    offering,
    'حالا همین رون را برای این نیت بخوان.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
