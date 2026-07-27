import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/monetization_switch.dart';
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
class ProfilePlaceholderPage extends ConsumerWidget {
  const ProfilePlaceholderPage({super.key});

  void _tapNav(BuildContext context, int index) {
    if (index == 1) {
      context.go(AppRoutes.allFortunesPath);
    } else if (index == 2) {
      context.go(AppRoutes.homePath);
    } else if (index == 3) {
      context.go(AppRoutes.historyPath);
    }
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('این بخش به‌زودی فعال می‌شود')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppPalette.nightDeep,
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 0,
        onTap: (i) => _tapNav(context, i),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
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
            _terms(context),
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
      ),
    );
  }

  /// Terms, in the reader's own language rather than a wall of legalese.
  ///
  /// This replaces the one-line reminder that used to sit under every reading.
  /// It says the same thing with more room, in the place a person goes looking
  /// for it — and it says it once, so the reading itself can stay a reading.
  static Widget _terms(BuildContext context) {
    final c = context.fortuneColors;
    const lines = [
      'بخت‌نگار برای سرگرمی و لحظه‌ای تأمل ساخته شده است. فال‌ها بر پایهٔ '
          'سنت‌های کهن نوشته می‌شوند و ارزش علمی یا پیش‌بینانه ندارند.',
      'هیچ فالی در این اپ پیش‌بینیِ قطعیِ آینده نیست و نباید مبنای تصمیم‌های '
          'مهمِ زندگی، پزشکی، حقوقی یا مالی قرار بگیرد.',
      'مسئولیتِ هر تصمیمی که می‌گیری با خودت است. بخت‌نگار و سازندگانش '
          'هیچ‌گونه مسئولیتی در قبال نتیجهٔ آن تصمیم‌ها ندارند.',
      'برای مسائل سلامتی، روانی، حقوقی یا مالی، به متخصصِ همان حوزه مراجعه کن. '
          'فال جای مشاوره نمی‌نشیند.',
      'متن غزل‌های دیوان حافظ از دادگان آزادِ پروژهٔ گنجور (ganjoor.net) '
          'آمده است — با مجوز MIT و با سپاس از گنجور.',
      'استفاده از بخت‌نگار به معنای پذیرفتن همین شرط‌هاست.',
    ];
    return GoldBorderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'قوانین و شرایط استفاده',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Said first and said plainly, because it is the sentence the owner
          // wants nobody to be able to miss.
          Text(
            'بخت‌نگار فقط یک برنامهٔ فال است و هیچ‌گونه مسئولیتِ حقوقی '
            'بر عهده نمی‌گیرد.',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              height: 1.9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) ...[
            Text(
              '• $line',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12,
                height: 1.9,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
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
