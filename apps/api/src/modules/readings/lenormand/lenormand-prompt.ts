import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import {
  VOICE,
  languageDirective,
  languageReminder,
  personaFor,
} from '../providers/prompt-builder';
import type { LenormandCard } from './lenormand-deck';

/**
 * The Lenormand raw engine's prompt. The card is already drawn from the real
 * deck and its traditional meaning is handed over here, so «کارتِ ساختگی نساز»
 * is kept by the deck, not asked of the model. The model's job narrows to
 * reading this one real card for the user's intention.
 */

const LENORMAND_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"interpretationForIntention":"پیوندِ این کارت با نیتِ کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این کارت در یک بند",',
  '"caution":"هشدارِ ملایمِ این کارت در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'فقط دربارهٔ همین کارت بنویس. کارتِ دیگری نام نبر و معنایی خارج از سنتِ',
  'همین کارت به آن نبند.',
].join('\n');

const LENORMAND_FRAMING = [
  'فال لنورماند است و کارتِ واقعیِ کشیده‌شده و معنای سنتی‌اش در ادامه آمده است.',
  'کارِ تو خواندنِ همین کارت برای نیتِ کاربر است — با احترام به معنای سنتی،',
  'بی‌قضاوت و بدونِ حکمِ قطعی. تفسیر باید از همین کارت برخیزد نه از کارتی دیگر.',
].join('\n');

export function buildLenormandPrompt(
  card: LenormandCard,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const language = languageDirective(profile?.locale, [
    'interpretationForIntention',
    'hope',
    'caution',
    'practicalAdvice',
  ]);
  const system = [VOICE, '', LENORMAND_FRAMING, '', LENORMAND_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .concat(language ? ['', language] : [])
    .join('\n');

  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const reminder = languageReminder(profile?.locale);
  const user = [
    `کارتِ کشیده‌شده: «${card.nameFa}».`,
    `معنای سنتیِ این کارت: ${card.meaningFa}`,
    offering,
    'حالا همین کارت را برای این نیت بخوان.',
    ...(reminder ? [reminder] : []),
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
