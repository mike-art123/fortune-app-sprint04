import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import { VOICE, personaFor } from '../providers/prompt-builder';
import type { QuranVerse } from './quran-deck';

/**
 * The Quran tafa'ul prompt. A real, verified verse is chosen and handed here
 * with its translation; the model's job is a GENTLE reflection tying it to the
 * user's intention — never a good/bad verdict, never a fatwa, never fear. The
 * verse is a point of hope; true istikhara is prayer, and the reading says so.
 */

const QURAN_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"reflectionForIntention":"تأملی ملایم که این آیه را به نیتِ کاربر پیوند می‌دهد، دو تا سه بند با \\n\\n",',
  '"hope":"روشنی و امیدِ این آیه در یک بند",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'این تفأل است، نه حکم و نه فتوا و نه پیش‌گویی. آیه را «خوب» یا «بد» نخوان و',
  'دربارهٔ آینده حکمِ قطعی نده؛ فقط از معنا و امیدِ همین آیه برای دلِ کاربر بگو.',
].join('\n');

const QURAN_FRAMING = [
  'تفأل به قرآن است؛ یک آیهٔ واقعی و معنایش در ادامه آمده است.',
  'کارِ تو تأملی محترمانه و امیدبخش بر همین آیه برای نیتِ کاربر است — با',
  'فروتنی، بی‌قضاوت، و بدونِ ترساندن. آیه چراغِ تأمل است، نه فرمان؛ و استخارهٔ',
  'حقیقی با نماز و توکل است. تفسیری خارج از معنای همین آیه به آن نبند.',
].join('\n');

export function buildQuranPrompt(
  verse: QuranVerse,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const system = [VOICE, '', QURAN_FRAMING, '', QURAN_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .join('\n');

  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const user = [
    `آیه (سورهٔ ${verse.surahNameFa}، آیهٔ ${verse.ayah}):`,
    verse.arabic,
    `ترجمه: ${verse.translationFa}`,
    offering,
    'حالا بر همین آیه برای این نیت، با احترام و امید تأمل کن.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
