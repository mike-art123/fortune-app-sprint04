import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../design_system/components/fortune_card.dart';
import '../../../../design_system/components/fortune_divider.dart';
import '../../../../design_system/components/fortune_empty_state.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../../../design_system/theme/fortune_theme_extension.dart';
import '../../application/wallet_controller.dart';
import '../../domain/entitlement_status.dart';
import '../../domain/wallet_summary.dart';

/// The coin wallet. The balance is the backend's word, rendered large in
/// Persian digits with the restrained gold accent — a line, never a fill.
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final state = ref.watch(walletControllerProvider);

    return FortuneScaffold(
      appBar: AppBar(title: Text(s.walletTitle)),
      child: switch (state) {
        WalletLoading() => const Center(child: FortuneLoading()),
        WalletFailed(:final failure) => FortuneErrorState(
            message: FailureMessageResolver.resolve(failure),
            reassurance: s.errorReassurance,
            retryLabel: s.actionRetry,
            onRetry: () => ref.read(walletControllerProvider.notifier).retry(),
          ),
        WalletLoaded(:final summary, :final entitlement) => _WalletView(
            summary: summary,
            entitlement: entitlement,
          ),
      },
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView({required this.summary, required this.entitlement});

  final WalletSummary summary;
  final EntitlementStatus? entitlement;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final fa = Localizations.localeOf(context).languageCode == 'fa';

    final balanceText = fa ? summary.balance.toPersianDigits : summary.balance.toString();

    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Balance — large, quiet, with the illumination line beneath.
        FortuneFadeIn(
          child: Column(
            children: [
              Text(
                balanceText,
                textAlign: TextAlign.center,
                style: textTheme.displayMedium?.copyWith(height: 1.2),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                s.walletBalanceUnit,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 56,
                height: 2,
                decoration: BoxDecoration(
                  color: c.goldWarm.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              // Sprint 04: the backend's word on cost/coverage — shown only
              // when known; the client never invents a price.
              if (entitlement case final e?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  e.hasActiveSubscription
                      ? s.walletSubscriptionActive
                      : s.walletReadingCost(
                          fa ? e.cost.toPersianDigits : e.cost.toString(),
                        ),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: c.textMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Daily reward — honest "coming soon", not a dead button pretending.
        FortuneFadeIn(
          duration: const Duration(milliseconds: 380),
          child: FortuneCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.walletDailyRewardTitle,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        s.walletDailyRewardBody,
                        style: textTheme.bodySmall?.copyWith(
                          color: c.textMuted,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  s.comingSoon,
                  style: textTheme.labelMedium?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const FortuneDivider(),
        const SizedBox(height: AppSpacing.md),

        Text(s.walletHistoryTitle, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        if (summary.entries.isEmpty)
          FortuneEmptyState(title: s.walletHistoryEmpty)
        else
          ...summary.entries.map(
            (entry) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: _CoinEntryRow(entry: entry),
            ),
          ),
      ],
    );
  }
}

class _CoinEntryRow extends StatelessWidget {
  const _CoinEntryRow({required this.entry});

  final CoinEntry entry;

  String _label(BuildContext context) {
    final s = context.strings;
    return switch (entry.kind) {
      'starter' => s.walletKindStarter,
      'daily' => s.walletKindDaily,
      'spend' || 'debit' => s.walletKindSpend,
      'refund' => s.walletKindRefund,
      _ => entry.reason ?? entry.kind,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fortuneColors;
    final textTheme = Theme.of(context).textTheme;
    final fa = Localizations.localeOf(context).languageCode == 'fa';

    final magnitude = fa ? entry.amount.abs().toPersianDigits : entry.amount.abs().toString();
    // Direction sign placed for RTL readability: «+۳۰» / «−۲».
    final amountText = entry.isCredit ? '+$magnitude' : '−$magnitude';

    return Row(
      children: [
        Expanded(
          child: Text(
            _label(context),
            style: textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          amountText,
          textDirection: TextDirection.ltr,
          style: textTheme.bodyMedium?.copyWith(
            color: entry.isCredit ? c.accentSecondary : c.textMuted,
          ),
        ),
      ],
    );
  }
}
