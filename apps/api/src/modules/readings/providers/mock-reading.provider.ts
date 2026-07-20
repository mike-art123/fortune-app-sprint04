import { Injectable } from '@nestjs/common';
import type { FortuneCatalogEntry } from '../fortune-catalog';
import type { ReadingInputDto } from '../dto/create-reading.dto';
import type { GeneratedReading, ReadingProvider } from './reading-provider.interface';

/**
 * Structured mock provider (Sprint 02). Produces calm, honest Persian copy in
 * the product register (Calm > Excitement, Hope > Urgency). It NEVER pretends
 * to be prophecy — the manifesto frames readings as reflection.
 * Replaced by the real orchestration of doc 56 without contract changes.
 */
@Injectable()
export class MockReadingProvider implements ReadingProvider {
  async generate(fortune: FortuneCatalogEntry, input: ReadingInputDto): Promise<GeneratedReading> {
    switch (fortune.inputKind) {
      case 'intention':
        return {
          title: this.intentionTitle(fortune),
          reading: [
            input.intention
              ? 'نیتی که با خود آوردی، شنیده شد.'
              : 'نیتت را در دل نگه داشتی؛ همان کافی است.',
            '',
            'این روزها آرام‌تر از آن‌اند که به چشم می‌آیند. آنچه در دلت روشن است، راهش را پیدا می‌کند — نه با شتاب، که با پیوستگی.',
            'اگر تردیدی هست، نشانه‌ی بی‌راهی نیست؛ نشانه‌ی آن است که برایت مهم است.',
            '',
            'برای امروز: یک قدمِ کوچک به‌سوی همان نیت بردار، و بگذار باقی‌اش آرام برسد.',
          ].join('\n'),
        };

      case 'longText':
        return {
          title: 'آنچه خوابت زمزمه می‌کند',
          reading: [
            'خوابی که تعریف کردی، بیش از آن‌که پیشگویی باشد، آینه است.',
            '',
            'تصویرهای خواب معمولاً از چیزی می‌گویند که در بیداری فرصتِ گفتنش نبوده. آنچه در خوابت پررنگ بود، همان‌جایی است که ذهنت می‌خواهد آرام بگیرد.',
            '',
            'برای امروز: چند دقیقه‌ای با خودت خلوت کن و بگذار همان تصویر، بی‌قضاوت، کنارت بنشیند.',
          ].join('\n'),
        };

      case 'twoNames': {
        const a = input.selfName ?? '';
        const b = input.otherName ?? '';
        return {
          title: 'پیوندِ دو نام',
          reading: [
            `${a} و ${b} —`,
            '',
            'هر پیوندی زبانِ خودش را دارد؛ زبانی که با شنیدن ساخته می‌شود، نه با حدس‌زدن.',
            'آنچه این پیوند را گرم نگه می‌دارد، همان لحظه‌های کوچکِ توجه است که به چشم نمی‌آیند ولی می‌مانند.',
            '',
            'برای امروز: یک جمله‌ی مهربان، بی‌مناسبت، می‌تواند فاصله‌ها را کوتاه کند.',
          ].join('\n'),
        };
      }
    }
  }

  private intentionTitle(fortune: FortuneCatalogEntry): string {
    return fortune.id === 'tarot' ? 'کارتی که برای تو برگشت' : 'پیامی از دیوان';
  }
}
