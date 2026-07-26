import 'package:flutter/material.dart';

import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';

/// Coffee (fāl-e ghahve) guide — an honest, content-rich screen for a fortune
/// whose live reading backend isn't ready. It teaches the ritual and the
/// traditional meaning of eight cup symbols, and says plainly that the full
/// personalised cup reading is «به‌زودی». No dead cards, no fake reading.
class CoffeeGuidePage extends StatelessWidget {
  const CoffeeGuidePage({super.key});

  static const _steps = [
    ('۱', 'فنجان را با نیت بنوش و تهِ آن کمی باقی بگذار.'),
    ('۲', 'نعلبکی را روی فنجان بگذار و سه بار بچرخان.'),
    ('۳', 'فنجان را وارونه کن و بگذار خنک شود.'),
    ('۴', 'نقش‌ها را بخوان — هر نماد پیامی دارد.'),
  ];

  static const _symbols = [
    ('sym_bird', 'پرنده', 'خبری خوش در راه است.'),
    ('sym_fish', 'ماهی', 'روزی و برکت و بختِ باز.'),
    ('sym_heart', 'قلب', 'عشقی تازه یا پیوندی نزدیک.'),
    ('sym_tree', 'درخت', 'آرزویی که به بار می‌نشیند.'),
    ('sym_road', 'راه', 'سفری یا تصمیمی تازه.'),
    ('sym_mountain', 'کوه', 'مانعی که با صبر پشتِ سر می‌گذاری.'),
    ('sym_eye', 'چشم', 'مراقبِ نگاهِ حسود باش.'),
    ('sym_snake', 'مار', 'هشدار؛ دشمنی پنهان.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    return FortuneScaffold(
      appBar: const FortuneAppBar(title: Text('فال قهوه')),
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
            'آیینِ فالِ قهوه',
            style: textTheme.titleLarge?.copyWith(color: c.goldWarm),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'فنجان را با نیت بنوش، وارونه کن، و بگذار نقش‌ها راز بگویند.',
            style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final s in _steps) _step(context, s.$1, s.$2),
          const SizedBox(height: AppSpacing.md),
          Text(
            'نمادها و معناها',
            style: textTheme.titleMedium?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final sym in _symbols)
            _SymbolCard(id: sym.$1, name: sym.$2, meaning: sym.$3),
          const SizedBox(height: AppSpacing.md),
          GoldBorderContainer(
            gradient: AppGradients.rewardWash,
            glow: true,
            child: Column(
              children: [
                Text(
                  'تفسیرِ کاملِ فنجانِ تو به‌زودی',
                  style: textTheme.titleSmall?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'به‌زودی می‌توانی عکسِ فنجانت را بفرستی و تفسیر بگیری.',
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
