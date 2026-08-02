import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/social_links_switch.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../core/platform/telegram_top_inset.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../application/profile_controller.dart';
import '../../domain/user_profile.dart';
import '../widgets/edit_profile_sheet.dart';

/// Where an invitation should send whoever receives it.
///
/// The web build hands out the Mini App it lives inside, and the Play build
/// hands out its own store listing. An iPhone must hand out neither: Apple
/// asks that an app not include "names, icons, or imagery of other mobile
/// platforms or alternative app marketplaces in your app or metadata"
/// (App Review Guideline 2.3.10), and a play.google.com link sitting in the
/// share sheet is precisely that. It shares the app's own site instead, which
/// also happens to be the only one of the three that works on whatever phone
/// the invitation lands on.
///
/// Pure and top-level so the choice is a unit test rather than a hope.
String inviteDestination() {
  if (kIsWeb) return 'https://t.me/Bakhtnegarbot/Bakhtnegar';
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return 'https://app.bakhtnegar.com';
  }
  return 'https://play.google.com/store/apps/details?id=com.bakhtnegar.app';
}

/// Premium profile screen (BakhtNegar visual reference): the real name and
/// birth month from the profile (scope §16, editable in place), journey
/// stats and an ornate menu list.
class ProfilePlaceholderPage extends ConsumerStatefulWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  ConsumerState<ProfilePlaceholderPage> createState() =>
      _ProfilePlaceholderPageState();
}

class _ProfilePlaceholderPageState
    extends ConsumerState<ProfilePlaceholderPage> {
  // Telegram's control row (Close · ⌄ · …) floats over the mini app, so the
  // header — and its avatar — sat underneath it. Listen for the inset the
  // way Home and All-Fortunes do, and pad the top by the same amount.
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

  void _tapNav(BuildContext context, int index) {
    if (index == 1) {
      context.go(AppRoutes.allFortunesPath);
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
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 0,
        onTap: (i) => _tapNav(context, i),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        children: [
          SizedBox(height: telegramTopInset(context)),
          _header(context, profile),
          const SizedBox(height: AppSpacing.md),
          _menu(
            context,
            Icons.history,
            context.strings.profileHistory,
            () => context.push(AppRoutes.historyPath),
          ),
          _menu(
            context,
            Icons.bookmark_border,
            context.strings.savedTitle,
            () => context.push(AppRoutes.savedPath),
          ),
          _menu(
            context,
            Icons.favorite_border,
            context.strings.intentionsTitle,
            () => context.push(AppRoutes.intentionsPath),
          ),
          _menu(
            context,
            Icons.settings_outlined,
            context.strings.settingsTitle,
            () => context.push(AppRoutes.settingsPath),
          ),
          _menu(
            context,
            Icons.support_agent_outlined,
            context.strings.contactTitle,
            () => context.push(AppRoutes.contactPath),
          ),
          _menu(
            context,
            Icons.info_outline_rounded,
            context.strings.aboutTitle,
            () => context.push(AppRoutes.aboutPath),
          ),
          const SizedBox(height: AppSpacing.sm),
          _personalization(context, ref, profile),
          const SizedBox(height: AppSpacing.lg),
          // Off for the first iOS submission — see social_links_switch.dart.
          // Compile-time, so the iOS binary carries no channel address at all.
          if (kSocialLinksEnabled) ...[
            _inviteCard(context),
            const SizedBox(height: AppSpacing.sm),
            _socialRow(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, UserProfile? profile) {
    final c = context.fortuneColors;
    final month = birthMonthLabel(
      profile?.birthMonth,
      Localizations.localeOf(context).languageCode,
    );
    return GoldBorderContainer(
      glow: true,
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icons/avatar_default.jpg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 60,
                height: 60,
                color: AppPalette.gemDeep,
                alignment: Alignment.center,
                child: Icon(Icons.person, color: c.goldWarm, size: 32),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? context.strings.homeGuestName,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (month != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.strings.profileBorn(month),
                    style: TextStyle(color: c.goldWarm, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => showEditProfileSheet(context),
            tooltip: context.strings.profileEditTooltip,
            icon: Icon(Icons.edit_outlined, color: c.goldWarm, size: 20),
          ),
        ],
      ),
    );
  }

  /// Scope §4: personalization is a courtesy, so it must be refusable — in one
  /// tap, in plain words, and without hunting through a settings tree.
  Widget _personalization(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) {
    final c = context.fortuneColors;
    final on = !(profile?.personalizationOptOut ?? false);
    return GoldBorderContainer(
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: on,
        onChanged: profile == null
            ? null
            : (value) => ref
                .read(profileControllerProvider.notifier)
                .updateProfile(personalizationOptOut: !value),
        title: Text(
          context.strings.profileRecsTitle,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          context.strings.profileRecsBody,
          style: TextStyle(color: c.textMuted, fontSize: 11),
        ),
        activeTrackColor: c.goldWarm.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final c = context.fortuneColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: LuxuryCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: c.goldWarm, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_left, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  /// Invite: share the Mini App through the Telegram share dialog on web; the
  /// native builds turn the same link into the system share sheet.
  Future<void> _shareApp() async {
    final bridge = ref.read(telegramBridgeProvider);
    final appUrl = inviteDestination();
    final url = Uri(
      scheme: 'https',
      host: 't.me',
      path: 'share/url',
      queryParameters: {
        'url': appUrl,
        'text': context.strings.inviteShareText,
      },
    ).toString();
    await bridge.openTelegramLink(url);
  }

  Future<void> _openUrl(String url, {bool telegram = false}) async {
    final bridge = ref.read(telegramBridgeProvider);
    if (telegram) {
      await bridge.openTelegramLink(url);
    } else {
      await bridge.openLink(url);
    }
  }

  Widget _inviteCard(BuildContext context) {
    final c = context.fortuneColors;
    return LuxuryCard(
      glow: true,
      onTap: _shareApp,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: AppGradients.goldSheen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ios_share,
              color: AppPalette.nightDeep,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.strings.inviteTitle,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.strings.inviteBody,
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: c.textMuted, size: 20),
        ],
      ),
    );
  }

  /// Telegram channel + Instagram as two full-bleed, brand-coloured tiles.
  Widget _socialRow() {
    return SizedBox(
      height: 132,
      child: Row(
        children: [
          Expanded(
            child: _socialCard(
              icon: Icons.send_rounded,
              label: context.strings.socialTelegram,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
              ),
              onTap: () => _openUrl('https://t.me/bakhtnegar', telegram: true),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _socialCard(
              icon: Icons.camera_alt_rounded,
              label: context.strings.socialInstagram,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737),
                ],
              ),
              onTap: () => _openUrl('https://instagram.com/bakhtnegar_app'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 44),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
