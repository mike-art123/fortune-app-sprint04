import type { PromptMessage } from '../../../common/ai/prompt-message';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { ReadingProfileContext } from '../providers/reading-provider.interface';
import { VOICE, personaFor } from '../providers/prompt-builder';
import type { TasbihResult } from './tasbih-count';

/**
 * The tasbih istikhara prompt. The outcome is already counted here, so the
 * model never decides it — its job is to read this one real outcome for the
 * intention, gently. The humility of istikhara is written into the framing:
 * طلبِ خیر از خداوند, never a command, never a prophecy.
 */

const TASBIH_CONTRACT = [
  'خروجی را فقط و فقط به‌صورت یک شیء JSON معتبر برگردان.',
  'بدون هیچ متن اضافه، بدون توضیح، بدون بک‌تیک، بدون ```json.',
  '',
  'ساختار دقیق:',
  '{"interpretationForIntention":"خواندنِ همین نتیجه برای نیتِ کاربر، دو تا سه بند با \\n\\n",',
  '"hope":"روشنیِ این نتیجه در یک بند",',
  '"caution":"یادآوریِ ملایم در یک بند، بدون ترس",',
  '"practicalAdvice":"یک پیشنهاد سادهٔ امروز در یک جمله، بدون «برای امروز:»"}',
  '',
  'نتیجهٔ استخاره از پیش مشخص شده و در پیام آمده است؛ نتیجهٔ دیگری نساز و آن',
  'را عوض نکن. همین نتیجه را بخوان.',
].join('\n');

const TASBIH_FRAMING = [
  'فال تسبیح (استخاره) است و نتیجهٔ شمارشِ دانه‌ها در ادامه آمده است.',
  'استخاره طلبِ خیر از خداوند است، نه حکمِ حتمی و نه پیش‌گویی. کارِ تو خواندنِ',
  'همین نتیجه برای نیتِ کاربر است با فروتنی و احترام؛ او را به تدبیر و مشورت',
  'دعوت کن، نه به اطاعتِ کورکورانه، و هرگز نترسان. اگر نتیجه «صبر» است یعنی',
  'کمی درنگ و تأمل، نه شکست؛ و «متوسط» یعنی میانه، با احتیاط پیش برو.',
].join('\n');

export function buildTasbihPrompt(
  result: TasbihResult,
  input: ReadingInputDto,
  profile?: ReadingProfileContext,
): PromptMessage[] {
  const persona = personaFor(profile);
  const system = [VOICE, '', TASBIH_FRAMING, '', TASBIH_CONTRACT]
    .concat(persona ? ['', persona] : [])
    .join('\n');

  const intention = input.intention?.trim();
  const offering = intention
    ? `نیت کاربر: «${intention}»`
    : 'کاربر نیتش را در دل نگه داشته و چیزی ننوشته است. سکوت او را محترم بشمار.';

  const user = [
    `نتیجهٔ استخاره با تسبیح: «${result}».`,
    offering,
    'حالا همین نتیجه را برای این نیت، با احترام و فروتنی بخوان.',
  ].join('\n\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: user },
  ];
}
