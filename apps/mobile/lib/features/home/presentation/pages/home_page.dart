import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../core/platform/telegram_top_inset.dart';
import '../../../../design_system/components/fortune_cards.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/section_title.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_layout.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../fortunes/domain/fortune_catalog.dart';
import '../../../fortunes/domain/fortune_registry.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../profile/presentation/widgets/personalize_prompt.dart';
import '../../../search/application/search_providers.dart';
import '../../../search/presentation/widgets/fortune_search_bar.dart';

/// The premium landing screen: a cinematic featured fortune, a compact quick
/// action row, a curated horizontal rail and one asymmetric editorial section
/// over a deep night canvas. Composition-only; routes and backend contracts are
/// unchanged. The first viewport stays calm — not every fortune shows at once.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _safeArea = telegramSafeArea;
  bool _promptShown = false;

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
      context.go(AppRoutes.termsPath);
    }
  }

  /// Shows the gentle personalization card once per home mount, and only to a
  /// visitor who has neither completed onboarding nor opted out for good. It
  /// floats centered over home (a dialog, not a gate); saving or opting out
  /// both dismiss it, and the opt-out is remembered server-side so it never
  /// returns on any device.
  void _maybePromptPersonalize() {
    if (_promptShown) return;
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    if (profile == null) return;
    if (profile.onboardingCompleted) return;
    if (profile.personalizationOptOut) return;
    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.62),
        builder: (_) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(child: PersonalizePrompt()),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybePromptPersonalize();
    final topInset = telegramTopInset(context);

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
                    _FeaturedCarousel(
                      items: FortuneCatalog.popular,
                      onOpen: (id, live) => _openId(context, id, live),
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
}

/// Accent for a catalog id, falling back to gold when it is not a live ritual.
Color _accentFor(String id) {
  return FortuneRegistry.byId(id)?.accent ?? AppPalette.goldMid;
}

/// The opening card, ten fortunes deep. It turns itself every three seconds
/// and gives way to a finger at once; the dots underneath say which one is
/// showing and how many are left, so the movement reads as an invitation
/// rather than a banner that will not sit still.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.items, required this.onOpen});

  final List<FortuneItem> items;
  final void Function(String id, bool live) onOpen;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _dwell = Duration(seconds: 3);
  static const _glide = Duration(milliseconds: 420);

  final _controller = PageController();
  late final List<FortuneItem> _slides;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Shuffled here and only here. Shuffling in build would deal a new order
    // on every rebuild — the card would change under the reader's finger.
    _slides = List<FortuneItem>.of(widget.items)..shuffle();
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(_dwell, (_) {
      if (!mounted || !_controller.hasClients || _slides.length < 2) return;
      _controller.animateToPage(
        (_index + 1) % _slides.length,
        duration: _glide,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    // A swipe buys a full three seconds on the card it landed on, instead of
    // inheriting whatever was left of the previous one.
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return Column(
      children: [
        // The PageView needs a bounded height and the card carries the ratio,
        // so the ratio moves out here; the card's own AspectRatio then sees
        // tight constraints and passes them straight through.
        AspectRatio(
          aspectRatio: AppLayout.featuredWide,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, i) {
              final item = _slides[i];
              return FeaturedWideFortuneCard(
                id: item.$1,
                title: item.$2,
                accent: _accentFor(item.$1),
                onTap: () => widget.onOpen(item.$1, item.$4),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: _glide,
                width: i == _index ? 8 : 6,
                height: i == _index ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? c.goldWarm
                      : c.textMuted.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    // The name keeps the outer edge it always had; search takes the empty half
    // of the row rather than a band of its own, so the first fortune stays
    // above the fold.
    return Row(
      children: [
        const _ProfileChip(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) => FortuneSearchBar(
              remote: ref.watch(searchRepositoryProvider),
              hintText: 'جست‌وجوی فال',
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileChip extends ConsumerWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    // The confirmed name from onboarding — the same source the profile page
    // and the readings use, so the greeting cannot drift from the settings.
    // It is already persisted server-side, so it survives every return.
    final profileName =
        ref.watch(profileControllerProvider).valueOrNull?.displayName?.trim();
    final greeting = (profileName == null || profileName.isEmpty)
        ? 'مسافرِ بخت'
        : profileName;
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
          greeting,
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
