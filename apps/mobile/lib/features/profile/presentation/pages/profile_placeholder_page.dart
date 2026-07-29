import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
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

  void _soon(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('این بخش به‌زودی فعال می‌شود')),
    );
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
            'تاریخچهٔ فال‌ها',
            () => context.push(AppRoutes.historyPath),
          ),
          _menu(
            context,
            Icons.bookmark_border,
            'فال‌های نشان‌شده',
            () => context.push(AppRoutes.savedPath),
          ),
          _menu(
            context,
            Icons.favorite_border,
            'نیت‌های من',
            () => context.push(AppRoutes.intentionsPath),
          ),
          _menu(
            context,
            Icons.settings_outlined,
            'تنظیمات',
            () => context.push(AppRoutes.settingsPath),
          ),
          _menu(
            context,
            Icons.support_agent_outlined,
            'پشتیبانی و درباره ما',
            () => _soon(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _personalization(context, ref, profile),
          const SizedBox(height: AppSpacing.lg),
          _inviteCard(context),
          const SizedBox(height: AppSpacing.sm),
          _socialRow(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, UserProfile? profile) {
    final c = context.fortuneColors;
    final month = birthMonthFa(profile?.birthMonth);
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
                  profile?.displayName ?? 'مسافرِ بخت',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  month != null
                      ? 'متولدِ $month · جست‌وجوگرِ حقیقت'
                      : 'جست‌وجوگرِ حقیقت',
                  style: TextStyle(color: c.goldWarm, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 6,
                    backgroundColor: AppPalette.nightPanel,
                    color: AppPalette.goldMid,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showEditProfileSheet(context),
            tooltip: 'ویرایش نام و ماه تولد',
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
          'پیشنهاد بر پایهٔ فال‌های خودم',
          style: TextStyle(color: c.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          'خاموش که باشد، هیچ پیشنهادی ساخته نمی‌شود.',
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

  /// Invite: share the Mini App with friends through the Telegram share dialog.
  Future<void> _shareApp() async {
    final bridge = ref.read(telegramBridgeProvider);
    final url = Uri(
      scheme: 'https',
      host: 't.me',
      path: 'share/url',
      queryParameters: {
        'url': 'https://t.me/Bakhtnegarbot/Bakhtnegar',
        'text': 'با بخت‌نگار هر روز فال و استخاره بگیر ✨',
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
                  'دعوت از دوستان',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'بخت‌نگار را با دوستانت به اشتراک بگذار',
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
              label: 'کانال تلگرام',
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
              label: 'اینستاگرام',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737),
                ],
              ),
              onTap: () => _openUrl('https://instagram.com/bakhtnegar_fal'),
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
