import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/monetization_switch.dart';
import '../../../../core/platform/telegram_safe_area.dart';
import '../../../../core/platform/telegram_top_inset.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/components/premium_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../../audio/presentation/widgets/ambient_audio_card.dart';
import '../../../notifications/presentation/widgets/notification_settings_card.dart';
import '../../application/profile_controller.dart';
import '../../domain/user_profile.dart';
import '../widgets/edit_profile_sheet.dart';

/// Premium profile screen (BakhtNegar visual reference): the real name and
/// birth month from the profile (scope §16, editable in place), journey
/// stats, an ornate menu list and a VIP upsell card.
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
          // Coins are gone: the only stats are the user's own journey.
          Row(
            children: [
              _stat(context, Icons.auto_awesome, '۱۲۸', 'فال‌ها'),
              const SizedBox(width: AppSpacing.xs),
              _stat(context, Icons.local_fire_department, '۷', 'روز پیاپی'),
              const SizedBox(width: AppSpacing.xs),
              _stat(context, Icons.bookmark_border, '۱۲', 'نشان‌شده'),
            ],
          ),
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
            () => _soon(context),
          ),
          _menu(
            context,
            Icons.favorite_border,
            'نیت‌های من',
            () => _soon(context),
          ),
          _menu(
            context,
            Icons.insights_outlined,
            'آمار و دستاوردها',
            () => _soon(context),
          ),
          _menu(
            context,
            Icons.settings_outlined,
            'تنظیمات',
            () => _soon(context),
          ),
          _menu(
            context,
            Icons.support_agent_outlined,
            'پشتیبانی و درباره ما',
            () => _soon(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _personalization(context, ref, profile),
          const SizedBox(height: AppSpacing.sm),
          const AmbientAudioCard(),
          const NotificationSettingsCard(),
          const SizedBox(height: AppSpacing.sm),
          if (kMonetizationEnabled)
            _vip(context, () => context.push(AppRoutes.vipPath)),
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

  Widget _stat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final c = context.fortuneColors;
    return Expanded(
      child: GoldBorderContainer(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: c.goldWarm, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: TextStyle(color: c.textMuted, fontSize: 10)),
          ],
        ),
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

  Widget _vip(BuildContext context, VoidCallback onTap) {
    final c = context.fortuneColors;
    return GoldBorderContainer(
      gradient: AppGradients.rewardWash,
      glow: true,
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppPalette.goldHi,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نسخهٔ VIP',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'بدون تبلیغ، امکاناتِ بیشتر',
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PremiumButton(label: 'ارتقا', onPressed: onTap),
        ],
      ),
    );
  }
}
