import 'package:flutter/material.dart';

import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/models/localized_text.dart';

/// The four classical elements — an honest, content-rich astrology screen.
/// It teaches each element's temperament and its three zodiac signs, and says
/// plainly that a full personalised chart is «به‌زودی». No dead cards.
class ElementsGuidePage extends StatelessWidget {
  const ElementsGuidePage({super.key});

  static const _title = LocalizedText(
    fa: 'عناصر چهارگانه',
    en: 'The Four Elements',
    ar: 'العناصر الأربعة',
    tr: 'Dört Element',
  );

  static const _intro = LocalizedText(
    fa: 'هر برج به یکی از چهار عنصر تعلق دارد؛ عنصرِ تو زبانِ روحِ توست.',
    en: 'Every sign belongs to an element; yours speaks for your spirit.',
    ar: 'لكل برج عنصره؛ وعنصرك لسان روحك.',
    tr: 'Her burç bir elemente aittir; elementin ruhunun dilidir.',
  );

  static const _footerTitle = LocalizedText(
    fa: 'طالعِ کاملِ تو به‌زودی',
    en: 'Your full chart, coming soon',
    ar: 'طالعك الكامل قريبًا',
    tr: 'Tam yıldız haritan çok yakında',
  );

  static const _footerBody = LocalizedText(
    fa: 'به‌زودی با ماهِ تولدت طالعِ شخصی و کاملت را می‌خوانی.',
    en: 'Soon your birth month will unlock your full personal chart.',
    ar: 'قريبًا يفتح شهر ميلادك طالعك الشخصي الكامل.',
    tr: 'Yakında doğum ayınla kişisel ve tam taliini okuyacaksın.',
  );

  static const _elements = [
    (
      'el_fire',
      LocalizedText(
        fa: 'آتش',
        en: 'Fire',
        ar: 'نار',
        tr: 'Ateş',
      ),
      LocalizedText(
        fa: 'شور، اراده و رهبری',
        en: 'Passion, will, leadership',
        ar: 'شغف وإرادة وقيادة',
        tr: 'Tutku, irade ve liderlik',
      ),
      LocalizedText(
        fa: 'حمل · اسد · قوس',
        en: 'Aries · Leo · Sagittarius',
        ar: 'الحمل · الأسد · القوس',
        tr: 'Koç · Aslan · Yay',
      ),
    ),
    (
      'el_earth',
      LocalizedText(
        fa: 'خاک',
        en: 'Earth',
        ar: 'تراب',
        tr: 'Toprak',
      ),
      LocalizedText(
        fa: 'پایداری، صبر و واقع‌گرایی',
        en: 'Steadiness, patience, realism',
        ar: 'ثبات وصبر وواقعية',
        tr: 'Kararlılık, sabır ve gerçekçilik',
      ),
      LocalizedText(
        fa: 'ثور · سنبله · جدی',
        en: 'Taurus · Virgo · Capricorn',
        ar: 'الثور · العذراء · الجدي',
        tr: 'Boğa · Başak · Oğlak',
      ),
    ),
    (
      'el_air',
      LocalizedText(
        fa: 'باد',
        en: 'Air',
        ar: 'هواء',
        tr: 'Hava',
      ),
      LocalizedText(
        fa: 'اندیشه، ارتباط و آزادی',
        en: 'Thought, connection, freedom',
        ar: 'فكر وتواصل وحرية',
        tr: 'Düşünce, iletişim ve özgürlük',
      ),
      LocalizedText(
        fa: 'جوزا · میزان · دلو',
        en: 'Gemini · Libra · Aquarius',
        ar: 'الجوزاء · الميزان · الدلو',
        tr: 'İkizler · Terazi · Kova',
      ),
    ),
    (
      'el_water',
      LocalizedText(
        fa: 'آب',
        en: 'Water',
        ar: 'ماء',
        tr: 'Su',
      ),
      LocalizedText(
        fa: 'احساس، شهود و همدلی',
        en: 'Feeling, intuition, empathy',
        ar: 'إحساس وحدس وتعاطف',
        tr: 'Duygu, sezgi ve empati',
      ),
      LocalizedText(
        fa: 'سرطان · عقرب · حوت',
        en: 'Cancer · Scorpio · Pisces',
        ar: 'السرطان · العقرب · الحوت',
        tr: 'Yengeç · Akrep · Balık',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final t = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    return FortuneScaffold(
      appBar: FortuneAppBar(title: Text(_title.resolve(locale))),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _intro.resolve(locale),
            style: t.bodyMedium?.copyWith(color: c.textSecondary, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final e in _elements)
            _ElementCard(
              id: e.$1,
              name: e.$2.resolve(locale),
              trait: e.$3.resolve(locale),
              signs: e.$4.resolve(locale),
            ),
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            gradient: AppGradients.rewardWash,
            glow: true,
            child: Column(
              children: [
                Text(
                  _footerTitle.resolve(locale),
                  style: t.titleSmall?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _footerBody.resolve(locale),
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ElementCard extends StatelessWidget {
  const _ElementCard({
    required this.id,
    required this.name,
    required this.trait,
    required this.signs,
  });

  final String id;
  final String name;
  final String trait;
  final String signs;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GoldBorderContainer(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                'assets/elements/$id.jpg',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.auto_awesome, color: c.goldWarm, size: 30),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _info(context)),
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context) {
    final c = context.fortuneColors;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: t.titleSmall?.copyWith(color: c.goldWarm)),
        const SizedBox(height: 2),
        Text(trait, style: t.bodySmall?.copyWith(color: c.textSecondary)),
        const SizedBox(height: 2),
        Text(signs, style: t.labelSmall?.copyWith(color: c.textMuted)),
      ],
    );
  }
}
