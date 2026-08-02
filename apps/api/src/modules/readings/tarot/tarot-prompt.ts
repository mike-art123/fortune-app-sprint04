import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import {
  VOICE,
  languageDirective,
  languageReminder,
  personaFor,
} from '../providers/prompt-builder';
import type { TarotCard } from './tarot-deck';

/**
 * The tarot raw engine's prompt. The card is already drawn from the real deck
 * and its traditional meaning is handed over here, so «کارتِ ساختگی نساز» is
 * kept by the deck, not asked of the model. The model's job narrows to reading
 * this one real card — in this orientation — for the user's intention.
 */

const TAROT_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"interpretationForIntention":"پیوندِ این کارت با نیتِ کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این کارت در یک بند",',
  '"caution":"هشدارِ ملایمِ این کارت در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'فقط دربارهٔ همین کارت و همین وضعیت (راست یا وارونه) بنویس. کارتِ دیگری',
  'نام نبر و معنایی خارج از سنتِ همین کارت به آن نبند.',
].join('\n');

const TAROT_FRAMING = [
  'فال تاروت است و کارتِ واقعیِ کشیده‌شده و معنای سنتی‌اش در ادامه آمده است.',
  'کارِ تو خواندنِ همین کارت برای نیتِ کاربر است — با احترام به معنای سنتی،',
  'بی‌قضاوت و بدونِ حکمِ قطعی. تفسیر باید از همین کارت برخیزد نه از کارتی دیگر.',
].join('\n');

export function buildTarotPrompt(
  card: TarotCard,
  reversed: boolean,
  meaning: string,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const language = languageDirective(
    profile?.locale,
    ['interpretationForIntention', 'hope', 'caution', 'practicalAdvice'],
  );
  const system = [VOICE, '', TAROT_FRAMING, '', TAROT_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .concat(language ? ['', language] : [])
    .join('\n');

  const orientation = reversed ? 'وارونه' : 'راست';
  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const reminder = languageReminder(profile?.locale);
  const user = [
    `کارتِ کشیده‌شده: «${card.nameFa}» — وضعیت: ${orientation}.`,
    `معنای سنتیِ این کارت در همین وضعیت: ${meaning}`,
    offering,
    'حالا همین کارت را برای این نیت بخوان.',
    ...(reminder ? [reminder] : []),
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
