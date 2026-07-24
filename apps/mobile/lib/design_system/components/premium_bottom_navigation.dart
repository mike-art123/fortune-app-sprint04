import 'package:flutter/material.dart';

import '../foundations/app_colors.dart';
import '../foundations/app_effects.dart';
import '../foundations/app_gradients.dart';
import '../foundations/app_spacing.dart';
import '../theme/fortune_theme_extension.dart';

/// Luxury bottom navigation: four side tabs around a raised, glowing central
/// «خانه» orb. Gold active state on a dark, gold-edged bar.
class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.person_outline, label: 'پروفایل'),
    (icon: Icons.auto_awesome_outlined, label: 'فال‌ها'),
    (icon: Icons.home_rounded, label: 'خانه'),
    (icon: Icons.menu_book_outlined, label: 'تاریخچه'),
    (icon: Icons.more_horiz, label: 'بیشتر'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        gradient: AppGradients.cardLuxe,
        border: Border(top: BorderSide(color: Color(0x38E7C25E))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: i == 2
                    ? _NavOrb(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        onTap: () => onTap(i),
                      )
                    : _NavItem(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        active: currentIndex == i,
                        onTap: () => onTap(i),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final color = active ? c.goldWarm : c.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

class _NavOrb extends StatelessWidget {
  const _NavOrb({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [AppPalette.gem, AppPalette.gemDeep],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.goldHi, width: 2),
              boxShadow: AppEffects.orbGlow,
            ),
            child: Icon(icon, size: 24, color: AppPalette.goldHi),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: TextStyle(color: c.goldWarm, fontSize: 10)),
        ],
      ),
    );
  }
}
