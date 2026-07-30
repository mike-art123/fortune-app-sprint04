import 'package:flutter/material.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/models/localized_text.dart';

/// Coffee (fāl-e ghahve) guide — an honest, content-rich screen for a fortune
/// whose live reading backend isn't ready. It teaches the ritual and the
/// traditional meaning of eight cup symbols, and says plainly that the full
/// personalised cup reading is «به‌زودی». No dead cards, no fake reading.
class CoffeeGuidePage extends StatelessWidget {
  const CoffeeGuidePage({super.key});

  static const _title = LocalizedText(
    fa: 'فال قهوه',
    en: 'Coffee Fortune',
    ar: 'قراءة الفنجان',
    tr: 'Kahve Falı',
  );

  static const _ritualTitle = LocalizedText(
    fa: 'آیینِ فالِ قهوه',
    en: 'The Coffee Ritual',
    ar: 'طقس قراءة الفنجان',
    tr: 'Kahve Falı Ritüeli',
  );

  static const _intro = LocalizedText(
    fa: 'فنجان را با نیت بنوش، وارونه کن، و بگذار نقش‌ها راز بگویند.',
    en: 'Drink with an intention, turn the cup over, and let the shapes speak.',
    ar: 'اشرب فنجانك بنيّة، ثم اقلبه، ودع النقوش تبوح بأسرارها.',
    tr: 'Fincanını niyetle iç, ters çevir ve bırak şekiller sırrını söylesin.',
  );

  static const _symbolsHeader = LocalizedText(
    fa: 'نمادها و معناها',
    en: 'Symbols and meanings',
    ar: 'الرموز ومعانيها',
    tr: 'Semboller ve anlamları',
  );

  static const _footerTitle = LocalizedText(
    fa: 'تفسیرِ کاملِ فنجانِ تو به‌زودی',
    en: 'Your full cup reading, coming soon',
    ar: 'قراءة فنجانك الكاملة قريبًا',
    tr: 'Fincanının tam yorumu çok yakında',
  );

  static const _footerBody = LocalizedText(
    fa: 'به‌زودی می‌توانی عکسِ فنجانت را بفرستی و تفسیر بگیری.',
    en: 'Soon you can send a photo of your cup and receive its reading.',
    ar: 'قريبًا سترسل صورة فنجانك وتتلقى قراءتها.',
    tr: 'Yakında fincanının fotoğrafını gönderip yorumunu alabileceksin.',
  );

  static const _steps = [
    LocalizedText(
      fa: 'فنجان را با نیت بنوش و تهِ آن کمی باقی بگذار.',
      en: 'Drink with an intention, leaving a little at the bottom.',
      ar: 'اشرب بنيّة واترك قليلًا في قاع الفنجان.',
      tr: 'Niyet ederek iç, dibinde biraz telve bırak.',
    ),
    LocalizedText(
      fa: 'نعلبکی را روی فنجان بگذار و سه بار بچرخان.',
      en: 'Place the saucer on top and swirl three times.',
      ar: 'ضع الصحن فوق الفنجان وأدره ثلاث مرات.',
      tr: 'Tabağı fincanın üstüne koy ve üç kez çevir.',
    ),
    LocalizedText(
      fa: 'فنجان را وارونه کن و بگذار خنک شود.',
      en: 'Turn the cup upside down and let it cool.',
      ar: 'اقلب الفنجان ودعه يبرد.',
      tr: 'Fincanı ters çevir ve soğumasını bekle.',
    ),
    LocalizedText(
      fa: 'نقش‌ها را بخوان — هر نماد پیامی دارد.',
      en: 'Read the shapes — every symbol carries a message.',
      ar: 'اقرأ النقوش — لكل رمز رسالة.',
      tr: 'Şekilleri oku — her sembolün bir mesajı var.',
    ),
  ];

  static const _symbols = [
    (
      'sym_bird',
      LocalizedText(
        fa: 'پرنده',
        en: 'Bird',
        ar: 'طائر',
        tr: 'Kuş',
      ),
      LocalizedText(
        fa: 'خبری خوش در راه است.',
        en: 'Good news is on its way.',
        ar: 'خبر سعيد في الطريق.',
        tr: 'Güzel bir haber yolda.',
      ),
    ),
    (
      'sym_fish',
      LocalizedText(
        fa: 'ماهی',
        en: 'Fish',
        ar: 'سمكة',
        tr: 'Balık',
      ),
      LocalizedText(
        fa: 'روزی و برکت و بختِ باز.',
        en: 'Provision, blessing, open fortune.',
        ar: 'رزق وبركة وحظ مفتوح.',
        tr: 'Bolluk, bereket ve açık baht.',
      ),
    ),
    (
      'sym_heart',
      LocalizedText(
        fa: 'قلب',
        en: 'Heart',
        ar: 'قلب',
        tr: 'Kalp',
      ),
      LocalizedText(
        fa: 'عشقی تازه یا پیوندی نزدیک.',
        en: 'A new love or a close bond.',
        ar: 'حب جديد أو رابطة قريبة.',
        tr: 'Yeni bir aşk ya da yakın bir bağ.',
      ),
    ),
    (
      'sym_tree',
      LocalizedText(
        fa: 'درخت',
        en: 'Tree',
        ar: 'شجرة',
        tr: 'Ağaç',
      ),
      LocalizedText(
        fa: 'آرزویی که به بار می‌نشیند.',
        en: 'A wish that bears fruit.',
        ar: 'أمنية تؤتي ثمارها.',
        tr: 'Meyvesini veren bir dilek.',
      ),
    ),
    (
      'sym_road',
      LocalizedText(
        fa: 'راه',
        en: 'Road',
        ar: 'طريق',
        tr: 'Yol',
      ),
      LocalizedText(
        fa: 'سفری یا تصمیمی تازه.',
        en: 'A journey or a fresh decision.',
        ar: 'سفر أو قرار جديد.',
        tr: 'Bir yolculuk ya da yeni bir karar.',
      ),
    ),
    (
      'sym_mountain',
      LocalizedText(
        fa: 'کوه',
        en: 'Mountain',
        ar: 'جبل',
        tr: 'Dağ',
      ),
      LocalizedText(
        fa: 'مانعی که با صبر پشتِ سر می‌گذاری.',
        en: 'An obstacle patience carries you past.',
        ar: 'عقبة تتجاوزها بالصبر.',
        tr: 'Sabırla aşacağın bir engel.',
      ),
    ),
    (
      'sym_eye',
      LocalizedText(
        fa: 'چشم',
        en: 'Eye',
        ar: 'عين',
        tr: 'Göz',
      ),
      LocalizedText(
        fa: 'مراقبِ نگاهِ حسود باش.',
        en: 'Mind the envious gaze.',
        ar: 'احذر عين الحسود.',
        tr: 'Kem gözlere dikkat et.',
      ),
    ),
    (
      'sym_snake',
      LocalizedText(
        fa: 'مار',
        en: 'Snake',
        ar: 'أفعى',
        tr: 'Yılan',
      ),
      LocalizedText(
        fa: 'هشدار؛ دشمنی پنهان.',
        en: 'A warning; a hidden foe.',
        ar: 'تحذير؛ عدوّ خفي.',
        tr: 'Gizli bir düşmana karşı bir uyarı.',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(_title.resolve(locale))),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              'assets/guide/coffee_guide.jpg',
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _ritualTitle.resolve(locale),
            style: textTheme.titleLarge?.copyWith(color: c.goldWarm),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _intro.resolve(locale),
            style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, s) in _steps.indexed)
            _step(context, _num(i + 1, lang), s.resolve(locale)),
          const SizedBox(height: AppSpacing.md),
          Text(
            _symbolsHeader.resolve(locale),
            style: textTheme.titleMedium?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final sym in _symbols)
            _SymbolCard(
              id: sym.$1,
              name: sym.$2.resolve(locale),
              meaning: sym.$3.resolve(locale),
            ),
          const SizedBox(height: AppSpacing.md),
          GoldBorderContainer(
            gradient: AppGradients.rewardWash,
            glow: true,
            child: Column(
              children: [
                Text(
                  _footerTitle.resolve(locale),
                  style: textTheme.titleSmall?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _footerBody.resolve(locale),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  static String _num(int n, String lang) =>
      lang == 'fa' ? n.toPersianDigits : '$n';

  Widget _step(BuildContext context, String n, String text) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppPalette.nightPanel,
            child: Text(
              n,
              style: textTheme.labelMedium?.copyWith(color: c.goldWarm),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymbolCard extends StatelessWidget {
  const _SymbolCard({
    required this.id,
    required this.name,
    required this.meaning,
  });

  final String id;
  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GoldBorderContainer(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                'assets/symbols/$id.jpg',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.auto_awesome, color: c.goldWarm, size: 28),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleSmall?.copyWith(color: c.goldWarm),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meaning,
                    style: textTheme.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
