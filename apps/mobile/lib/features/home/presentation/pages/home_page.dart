import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/monetization_switch.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../design_system/components/fortune_cards.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_layout.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_catalog.dart';
import '../../../fortunes/domain/fortune_registry.dart';

/// The premium landing screen: a cinematic featured fortune, a compact quick
/// action row, a curated horizontal rail and one asymmetric editorial section
/// over a deep night canvas. Composition-only; routes and backend contracts are
/// unchanged. The first viewport stays calm — not every fortune shows at once.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  void _openId(BuildContext context, String id, bool available) {
    if (id == 'coffee') {
      context.push(AppRoutes.coffeePath);
      return;
    }
    if (id == 'elements') {
      context.push(AppRoutes.elementsPath);
      return;
    }
    if (!available) {
      _soon(context);
      return;
    }
    context.push(AppRoutes.ritual(id));
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
    final topInset = _resolveTopInset(context);
    final hafez = FortuneRegistry.byId('hafez');

    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 2,
        onTap: (i) => _tapNav(context, i),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              top: topInset,
              left: AppLayout.pageMargin,
              right: AppLayout.pageMargin,
            ),
            child: const _TopBar(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.pageMargin,
                    0,
                    AppLayout.pageMargin,
                    AppSpacing.lg,
                  ),
                  children: [
                    if (hafez != null)
                      FeaturedWideFortuneCard(
                        id: hafez.id,
                        title: 'فال حافظ',
                        subtitle: 'نیت کن و از دیوان بپرس',
                        accent: hafez.accent,
                        cta: 'فال حافظ را باز کن',
                        onTap: () => _openId(context, hafez.id, true),
                      ),
                    const SizedBox(height: AppLayout.sectionGap),
                    _QuickActionsRow(
                      onOpen: (id) => _openId(context, id, true),
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    SectionTitle(
                      title: 'فال‌های محبوب',
                      actionLabel: 'مشاهده همه',
                      onAction: () => context.go(AppRoutes.allFortunesPath),
                    ),
                    const SizedBox(height: AppLayout.headingGap),
                    _CuratedRail(
                      items: FortuneCatalog.groups.first.items,
                      onOpen: (id, live) => _openId(context, id, live),
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    SectionTitle(
                      title: 'عشق و روابط',
                      actionLabel: 'مشاهده همه',
                      onAction: () => context.go(AppRoutes.allFortunesPath),
                    ),
                    const SizedBox(height: AppLayout.headingGap),
                    _EditorialLove(onOpen: (id) => _openId(context, id, true)),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top inset that clears Telegram's safe area + Close/More control row.
  double _resolveTopInset(BuildContext context) {
    final viewTop = MediaQuery.viewPaddingOf(context).top;
    if (_safeArea.isTelegram) {
      final top = _safeArea.topInset;
      if (top > 0.5) return top;
      final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
      final device = viewTop > 0 ? viewTop : (isIOS ? 59.0 : 24.0);
      return (device + (isIOS ? 44.0 : 12.0)).clamp(0.0, 200.0).toDouble();
    }
    return viewTop > 8 ? viewTop : 8.0;
  }
}

/// Accent for a catalog id, falling back to gold when it is not a live ritual.
Color _accentFor(String id) {
  return FortuneRegistry.byId(id)?.accent ?? AppPalette.goldMid;
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
        // Nothing is sold while monetization is paused, so nothing advertises
        // it either.
        if (kMonetizationEnabled) ...[
          const _VipChip(),
          const SizedBox(width: AppSpacing.xs),
        ],
        Icon(Icons.menu, color: c.goldWarm),
      ],
    );
  }
}

/// The only header status: a quiet VIP entry (no coin or gem balances exist).
class _VipChip extends StatelessWidget {
  const _VipChip();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => context.push(AppRoutes.vipPath),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.rewardWash,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppPalette.goldMid.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 16,
              color: AppPalette.goldHi,
            ),
            SizedBox(width: 4),
            Text(
              'VIP',
              style: TextStyle(
                color: AppPalette.goldHi,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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

/// The daily reading and the istikhara as two FULL fortune cards — exactly
/// the size and shape of every other fortune card (coffee, tarot, …), with
/// their own Firefly artwork resolved from the fortunes art folder.
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onOpen});

  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PortraitFortuneCard(
            id: 'daily',
            title: 'فال روزانه',
            subtitle: 'ویژهٔ امروز',
            accent: _accentFor('daily'),
            available: true,
            soonLabel: 'به‌زودی',
            onTap: () => onOpen('daily'),
          ),
        ),
        const SizedBox(width: AppLayout.cardGap),
        Expanded(
          child: PortraitFortuneCard(
            id: 'quran',
            title: 'استخاره',
            subtitle: 'استخارهٔ قرآن',
            accent: _accentFor('quran'),
            available: true,
            soonLabel: 'به‌زودی',
            onTap: () => onOpen('quran'),
          ),
        ),
      ],
    );
  }
}

/// Curated horizontal rail of compact landscape cards with a peek of the next.
class _CuratedRail extends StatelessWidget {
  const _CuratedRail({required this.items, required this.onOpen});

  final List<FortuneItem> items;
  final void Function(String id, bool available) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardW = (width * AppLayout.railWidthFraction)
            .clamp(200.0, AppLayout.railWidthMax)
            .toDouble();
        final cardH = cardW / AppLayout.compactLandscape;
        return SizedBox(
          height: cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppLayout.cardGap),
            itemBuilder: (context, i) {
              final it = items[i];
              return SizedBox(
                width: cardW,
                child: CompactLandscapeFortuneCard(
                  id: it.$1,
                  title: it.$2,
                  subtitle: it.$3,
                  accent: _accentFor(it.$1),
                  onTap: () => onOpen(it.$1, it.$4),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Asymmetric editorial block: one wide thematic band + a pair of portraits.
class _EditorialLove extends StatelessWidget {
  const _EditorialLove({required this.onOpen});

  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionFeatureCard(
          id: 'love',
          title: 'فال عشق',
          subtitle: 'دو نام، یک پیوند',
          accent: _accentFor('love'),
          onTap: () => onOpen('love'),
        ),
        const SizedBox(height: AppLayout.cardGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PortraitFortuneCard(
                id: 'marriage',
                title: 'فال ازدواج',
                subtitle: 'آیندهٔ ازدواج',
                accent: _accentFor('marriage'),
                available: true,
                soonLabel: 'به‌زودی',
                onTap: () => onOpen('marriage'),
              ),
            ),
            const SizedBox(width: AppLayout.cardGap),
            Expanded(
              child: PortraitFortuneCard(
                id: 'child',
                title: 'فال فرزند',
                subtitle: 'فرزند داری؟',
                accent: _accentFor('child'),
                available: true,
                soonLabel: 'به‌زودی',
                onTap: () => onOpen('child'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
