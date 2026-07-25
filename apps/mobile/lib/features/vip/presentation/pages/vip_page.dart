import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/gold_border_container.dart';
import '../../../../design_system/components/luxury_card.dart';
import '../../../../design_system/components/premium_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_gradients.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/vip_controller.dart';
import '../../domain/vip_status.dart';

/// «عضویت ویژه بخت‌نگار» — the only paid surface in the app. Plans are priced
/// in Telegram Stars; purchase opens Telegram's native sheet and activation is
/// confirmed by the backend. No coins, no packages, no virtual currency.
class VipPage extends ConsumerWidget {
  const VipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vipControllerProvider);

    return FortuneScaffold(
      appBar: AppBar(title: const Text('عضویت ویژه')),
      child: switch (state) {
        VipLoading() => const Center(child: FortuneLoading()),
        VipFailed(:final failure) => FortuneErrorState(
            message: FailureMessageResolver.resolve(failure),
            reassurance: 'اتصالت را چک کن و دوباره بیا.',
            retryLabel: 'دوباره تلاش کن',
            onRetry: () => ref.read(vipControllerProvider.notifier).retry(),
          ),
        VipLoaded(:final status, :final purchasing) =>
          _VipView(status: status, purchasing: purchasing),
      },
    );
  }
}

class _VipView extends ConsumerWidget {
  const _VipView({required this.status, required this.purchasing});

  final VipStatus status;
  final bool purchasing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      children: [
        _StatusCard(status: status),
        const SizedBox(height: AppSpacing.lg),
        const _Benefits(),
        const SizedBox(height: AppSpacing.lg),
        for (final plan in status.plans) ...[
          _PlanCard(plan: plan, purchasing: purchasing),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'اعضای VIP فال‌ها را بدون تبلیغ و محدودیت‌های عادی دریافت می‌کنند.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.fortuneColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final VipStatus status;

  String _faDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d'.toPersianDigits;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final expiresAt = status.expiresAt;
    return GoldBorderContainer(
      gradient: AppGradients.rewardWash,
      glow: true,
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppPalette.goldHi,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isVip ? 'عضو ویژه هستی ✨' : 'عضویت ویژه بخت‌نگار',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.isVip && expiresAt != null
                      ? 'فعال تا ${_faDate(expiresAt)}'
                      : 'همهٔ فال‌ها، بدون تبلیغ و بدون محدودیتِ روزانه',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  static const _items = [
    (Icons.block, 'بدون هیچ تبلیغی'),
    (Icons.all_inclusive, 'همهٔ فال‌ها بدون محدودیتِ روزانه'),
    (Icons.menu_book, 'تفسیرهای کامل و عمیق‌تر'),
    (Icons.history, 'تاریخچهٔ نامحدود'),
    (Icons.workspace_premium, 'نشانِ VIP کنار نامت'),
    (Icons.support_agent, 'پشتیبانی اولویت‌دار'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    return LuxuryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, label) in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, color: c.goldWarm, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: c.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.purchasing});

  final VipPlan plan;
  final bool purchasing;

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final outcome =
        await ref.read(vipControllerProvider.notifier).purchase(plan.id);
    if (!context.mounted) return;
    final message = switch (outcome) {
      'paid' => 'عضویت ویژه‌ات فعال شد ✨',
      'cancelled' => 'پرداخت لغو شد.',
      'pending' => 'پرداخت در حال بررسی است.',
      'unavailable' => 'پرداخت فقط داخلِ تلگرام ممکن است.',
      'busy' => 'کمی صبر کن…',
      _ => 'پرداخت انجام نشد؛ دوباره تلاش کن.',
    };
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fortuneColors;
    return LuxuryCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.titleFa,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${plan.stars.toString().toPersianDigits} ستاره',
                  style: TextStyle(color: c.goldWarm, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PremiumButton(
            label: purchasing ? '…' : 'خرید',
            onPressed: purchasing ? null : () => _buy(context, ref),
          ),
        ],
      ),
    );
  }
}
