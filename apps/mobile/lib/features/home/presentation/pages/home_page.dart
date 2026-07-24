import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/components/hero_banner.dart';
import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/premium_button.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/components/stat_chip.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_definition.dart';
import '../../../fortunes/domain/fortune_registry.dart';

/// The premium landing screen (BakhtNegar visual reference): a cinematic hero,
/// quick actions, popular fortunes and a daily-reward banner over a gold-edged
/// dark canvas with the raised central «خانه» orb. Logic-free — it drives the
/// existing fortune registry and routes; no backend contracts change.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, FortuneDefinition fortune) {
    if (!fortune.isAvailable) {
      _soon(context);
      return;
    }
    context.push(AppRoutes.ritual(fortune.id));
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(context.strings.comingSoonDetail)),
    );
  }

  void _tapNav(BuildContext context, int index) {
    if (index == 0) {
      context.go(AppRoutes.profilePath);
    } else if (index == 1) {
      context.go(AppRoutes.allFortunesPath);
    } else if (index == 3) {
      context.go(AppRoutes.historyPath);
    } else if (index == 4) {
      _soon(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 2,
        onTap: (i) => _tapNav(context, i),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            const _TopBar(),
            const SizedBox(height: AppSpacing.md),
            HeroBanner(
              title: 'فال و اسرار زندگی',
              subtitle: 'هر نیت: راهی‌ست به سوی یک پاسخ…',
              action: PremiumButton(
                label: 'نیت کن',
                icon: Icons.auto_awesome,
                onPressed: () => context.push(AppRoutes.ritual('hafez')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _QuickActions(onTap: () => _soon(context)),
            SectionTitle(
              title: 'فال‌های محبوب',
              actionLabel: 'مشاهده همه',
              onAction: () => context.go(AppRoutes.allFortunesPath),
            ),
            _FeaturedRow(onOpen: (f) => _open(context, f)),
            const SizedBox(height: AppSpacing.md),
            _RewardBanner(onClaim: () => _soon(context)),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Row(
      children: [
        const _ProfileChip(),
        const Spacer(),
        const StatChip(icon: Icons.monetization_on, value: '۲۴۵۰'),
        const SizedBox(width: AppSpacing.xs),
        const StatChip(
          icon: Icons.diamond,
          value: '۸۰',
          iconColor: AppPalette.gem,
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(Icons.menu, color: c.goldWarm),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/icons/avatar_default.jpg',
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: 34,
              height: 34,
              color: AppPalette.gemDeep,
              alignment: Alignment.center,
              child: Icon(Icons.person, size: 18, color: c.goldWarm),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'نیلوفر',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});

  final VoidCallback onTap;

  static const _items = [
    (icon: Icons.wb_sunny_outlined, label: 'فال روزانه'),
    (icon: Icons.card_giftcard, label: 'جایزهٔ روزانه'),
    (icon: Icons.casino_outlined, label: 'شانس امروز'),
    (icon: Icons.event_note_outlined, label: 'تقویم معنوی'),
    (icon: Icons.menu_book_outlined, label: 'استخاره'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: onTap,
            child: GoldBorderContainer(
              radius: AppRadius.lg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: c.goldWarm, size: 22),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.label,
                    style: TextStyle(color: c.textPrimary, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.onOpen});

  final void Function(FortuneDefinition fortune) onOpen;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FortuneRegistry.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final fortune = FortuneRegistry.all[i];
          return _FeaturedCard(
            fortune: fortune,
            locale: locale,
            onTap: () => onOpen(fortune),
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.fortune,
    required this.locale,
    required this.onTap,
  });

  final FortuneDefinition fortune;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return SizedBox(
      width: 132,
      child: LuxuryCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Emblem(
              id: fortune.id,
              icon: _iconFor(fortune.id),
              accent: fortune.accent,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              fortune.title.resolve(locale),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.goldWarm,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fortune.subtitle.resolve(locale),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({
    required this.id,
    required this.icon,
    required this.accent,
  });

  final String id;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.asset(
        'assets/fortunes/$id.jpg',
        height: 84,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [accent.withValues(alpha: 0.35), AppPalette.nightPanel],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalette.goldMid.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 40, color: AppPalette.goldHi),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.onClaim});

  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return GoldBorderContainer(
      gradient: AppGradients.rewardWash,
      glow: true,
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, size: 40, color: AppPalette.goldHi),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جایزهٔ روزانه',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'هر روز وارد شو و جایزه بگیر',
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PremiumButton(label: 'دریافت', onPressed: onClaim),
        ],
      ),
    );
  }
}

IconData _iconFor(String id) {
  switch (id) {
    case 'hafez':
      return Icons.menu_book;
    case 'tarot':
      return Icons.style;
    case 'dream':
      return Icons.nightlight_round;
    case 'love':
      return Icons.favorite;
    case 'coffee':
      return Icons.local_cafe;
    default:
      return Icons.auto_awesome;
  }
}
