import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../app/routing/fortune_destinations.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../core/platform/telegram_top_inset.dart';
import '../../../../design_system/components/fortune_cards.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_layout.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../search/application/search_providers.dart';
import '../../../search/presentation/widgets/fortune_search_bar.dart';
import '../../domain/fortune_catalog.dart';
import '../../domain/fortune_registry.dart';

Color _accentFor(String id) {
  return FortuneRegistry.byId(id)?.accent ?? AppPalette.goldMid;
}

/// «همه فال‌ها» — an editorial browse experience. Each theme opens with one
/// wide feature image, then its remaining fortunes flow as a two-column grid of
/// portrait cards: varied proportions, image-led, no repetitive square tiles.
class AllFortunesPage extends StatefulWidget {
  const AllFortunesPage({super.key});

  @override
  State<AllFortunesPage> createState() => _AllFortunesPageState();
}

class _AllFortunesPageState extends State<AllFortunesPage> {
  // Telegram reports its inset after the page is already built, so the page
  // has to listen rather than read once — the same contract HomePage keeps.
  final _safeArea = telegramSafeArea;

  @override
  void initState() {
    super.initState();
    _safeArea.addListener(_onSafeAreaChanged);
  }

  @override
  void dispose() {
    _safeArea.removeListener(_onSafeAreaChanged);
    super.dispose();
  }

  void _onSafeAreaChanged() {
    if (mounted) setState(() {});
  }

  void _open(BuildContext context, FortuneItem item) {
    // One shared map decides where a fortune leads, so a card and a search
    // result can never disagree about the same fortune.
    final path = FortuneDestinations.pathFor(item.$1);
    if (path != null) {
      context.push(path);
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
    } else if (index == 4) {
      context.go(AppRoutes.termsPath);
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
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: telegramTopInset(context)),
                ),
                // Search used to sit alone above everything, which put it under
                // Telegram's Close button — present, but impossible to tap. It
                // now shares the first heading's row, so it arrives with the
                // content instead of ahead of it (scope §2).
                for (final (index, group) in FortuneCatalog.groups.indexed)
                  ..._sectionSlivers(context, group, searchInTitle: index == 0),
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

  List<Widget> _sectionSlivers(
    BuildContext context,
    FortuneGroup group, {
    required bool searchInTitle,
  }) {
    final featured = group.items.first;
    final rest = group.items.skip(1).toList();
    // A lone last card would sit half-width beside an empty cell. Pull it
    // out and give it the same full-width feature treatment as the hero,
    // so every row stays filled and its image leads the whole frame.
    final tail = rest.length.isOdd ? rest.last : null;
    final gridItems = tail == null ? rest : rest.sublist(0, rest.length - 1);
    const pad = EdgeInsets.symmetric(horizontal: AppLayout.pageMargin);
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: SectionTitle(
            title: group.title,
            trailing: searchInTitle
                ? Consumer(
                    builder: (context, ref, _) => FortuneSearchBar(
                      remote: ref.watch(searchRepositoryProvider),
                      hintText: 'جست‌وجوی فال',
                    ),
                  )
                : null,
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: AppLayout.headingGap),
      ),
      SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: _featureCard(context, featured),
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
              final item = gridItems[i];
              final id = item.$1;
              final openable = FortuneDestinations.pathFor(id) != null;
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
            childCount: gridItems.length,
          ),
        ),
      ),
      if (tail != null) ...[
        const SliverToBoxAdapter(
          child: SizedBox(height: AppLayout.cardGap),
        ),
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: _featureCard(context, tail),
          ),
        ),
      ],
      const SliverToBoxAdapter(
        child: SizedBox(height: AppLayout.sectionGap),
      ),
    ];
  }

  Widget _featureCard(BuildContext context, FortuneItem item) {
    return SectionFeatureCard(
      id: item.$1,
      title: item.$2,
      subtitle: item.$3,
      accent: _accentFor(item.$1),
      onTap: () => _open(context, item),
    );
  }
}
