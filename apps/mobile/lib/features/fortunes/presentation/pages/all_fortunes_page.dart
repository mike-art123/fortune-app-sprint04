import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../domain/fortune_catalog.dart';

/// «همه فال‌ها» — the full browse grid. Every fortune has a real illustrated
/// card; the four backend-backed ones open the ritual, the rest are «به‌زودی».
class AllFortunesPage extends StatelessWidget {
  const AllFortunesPage({super.key});

  void _open(BuildContext context, FortuneItem item) {
    if (item.$4) {
      context.push(AppRoutes.ritual(item.$1));
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('این فال به‌زودی فعال می‌شود')),
      );
    }
  }

  void _tapNav(BuildContext context, int index) {
    if (index == 0) {
      context.go(AppRoutes.profilePath);
    } else if (index == 2) {
      context.go(AppRoutes.homePath);
    } else if (index == 3) {
      context.go(AppRoutes.historyPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 1,
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
            for (final group in FortuneCatalog.groups) ...[
              SectionTitle(title: group.title),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 0.72,
                children: [
                  for (final item in group.items)
                    _CatalogCard(item: item, onTap: () => _open(context, item)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item, required this.onTap});

  final FortuneItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final id = item.$1;
    final title = item.$2;
    final subtitle = item.$3;
    final live = item.$4;
    return LuxuryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              'assets/fortunes/$id.jpg',
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _fallback(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.goldWarm,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            live ? subtitle : 'به‌زودی',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: live ? c.textMuted : c.warning,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      height: 70,
      color: AppPalette.nightPanel,
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, color: AppPalette.goldMid),
    );
  }
}
