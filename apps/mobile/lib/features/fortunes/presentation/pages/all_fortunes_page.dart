import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/components/fortune_cards.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_layout.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../domain/fortune_catalog.dart';
import '../../domain/fortune_registry.dart';

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

Color _accentFor(String id) {
  return FortuneRegistry.byId(id)?.accent ?? AppPalette.goldMid;
}

/// «همه فال‌ها» — an editorial browse experience. Each theme opens with one
/// wide feature image, then its remaining fortunes flow as a two-column grid of
/// portrait cards: varied proportions, image-led, no repetitive square tiles.
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sm),
                ),
                for (final group in FortuneCatalog.groups)
                  ..._sectionSlivers(context, group),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sectionSlivers(BuildContext context, FortuneGroup group) {
    final featured = group.items.first;
    final rest = group.items.skip(1).toList();
    const pad = EdgeInsets.symmetric(horizontal: AppLayout.pageMargin);
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(child: SectionTitle(title: group.title)),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppLayout.headingGap),
      ),
      SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: SectionFeatureCard(
            id: featured.$1,
            title: featured.$2,
            subtitle: featured.$3,
            accent: _accentFor(featured.$1),
            onTap: () => _open(context, featured),
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppLayout.cardGap),
      ),
      SliverPadding(
        padding: pad,
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: AppLayout.portrait,
            mainAxisSpacing: AppLayout.cardGap,
            crossAxisSpacing: AppLayout.cardGap,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final item = rest[i];
              final id = item.$1;
              final live = item.$4;
              final openable = live || _guidedIds.contains(id);
              return PortraitFortuneCard(
                id: id,
                title: item.$2,
                subtitle: item.$3,
                accent: _accentFor(id),
                available: openable,
                soonLabel: 'به‌زودی',
                onTap: () => _open(context, item),
              );
            },
            childCount: rest.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppLayout.sectionGap),
      ),
    ];
  }
}
