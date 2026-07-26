import 'package:flutter/material.dart';

import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// The four classical elements — an honest, content-rich astrology screen.
/// It teaches each element's temperament and its three zodiac signs, and says
/// plainly that a full personalised chart is «به‌زودی». No dead cards.
class ElementsGuidePage extends StatelessWidget {
  const ElementsGuidePage({super.key});

  static const _elements = [
    ('el_fire', 'آتش', 'شور، اراده و رهبری', 'حمل · اسد · قوس'),
    ('el_earth', 'خاک', 'پایداری، صبر و واقع‌گرایی', 'ثور · سنبله · جدی'),
    ('el_air', 'باد', 'اندیشه، ارتباط و آزادی', 'جوزا · میزان · دلو'),
    ('el_water', 'آب', 'احساس، شهود و همدلی', 'سرطان · عقرب · حوت'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final t = Theme.of(context).textTheme;
    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('عناصر چهارگانه')),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'هر برج به یکی از چهار عنصر تعلق دارد؛ عنصرِ تو زبانِ روحِ توست.',
            style: t.bodyMedium?.copyWith(color: c.textSecondary, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final e in _elements)
            _ElementCard(id: e.$1, name: e.$2, trait: e.$3, signs: e.$4),
          const SizedBox(height: AppSpacing.sm),
          GoldBorderContainer(
            gradient: AppGradients.rewardWash,
            glow: true,
            child: Column(
              children: [
                Text(
                  'طالعِ کاملِ تو به‌زودی',
                  style: t.titleSmall?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'به‌زودی با ماهِ تولدت طالعِ شخصی و کاملت را می‌خوانی.',
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
