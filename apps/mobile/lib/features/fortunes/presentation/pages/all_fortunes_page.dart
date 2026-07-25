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

/// Fortunes that open a real content screen (a guide) instead of a live
/// ritual reading. These are never «به‌زودی» — they lead somewhere real.
const _guidedIds = {'coffee', 'elements'};

String? _guidePathFor(String id) {
  switch (id) {
    case 'coffee':
      return AppRoutes.coffeePath;
    case 'elements':
      return AppRoutes.elementsPath;
    default:
      return null;
  }
}

/// «همه فال‌ها» — the full browse grid. Every fortune has a real illustrated
/// card; live ones open the ritual, guided ones open a content screen, and the
/// rest are honest «به‌زودی».
class AllFortunesPage extends StatelessWidget {
  const AllFortunesPage({super.key});

  void _open(BuildContext context, FortuneItem item) {
    final guide = _guidePathFor(item.$1);
    if (guide != null) {
      context.push(guide);
      return;
    }
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
              GridView.extent(
                // Responsive: cells cap at ~220px wide, so desktop gets more
                // columns instead of three giant cells that shrink the art to
                // a thin strip. childAspectRatio leaves room for image + text.
                maxCrossAxisExtent: 220,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 0.9,
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
    final openable = live || _guidedIds.contains(id);
    return LuxuryCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AspectRatio(
              // Matches the artwork (640x498 ≈ 1.28), so the FULL hero shows
              // with no crop or distortion; height scales with the card width.
              aspectRatio: 1.28,
              child: Image.asset(
                'assets/fortunes/$id.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _fallback(),
              ),
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
            openable ? subtitle : 'به‌زودی',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: openable ? c.textMuted : c.warning,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return const ColoredBox(
      color: AppPalette.nightPanel,
      child: Center(
        child: Icon(Icons.auto_awesome, color: AppPalette.goldMid),
      ),
    );
  }
}
