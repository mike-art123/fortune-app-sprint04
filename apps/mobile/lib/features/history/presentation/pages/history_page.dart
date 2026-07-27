import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_button.dart';
import '../../../../design_system/components/fortune_empty_state.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/components/premium_bottom_navigation.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../application/history_controller.dart';
import '../widgets/history_card.dart';
import '../widgets/history_summary_card.dart';

/// The journal — every reading the user has received, newest first.
/// Calm surface: a stale page or failed load never scolds the user.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  void _tapNav(BuildContext context, int index) {
    if (index == 0) {
      context.go(AppRoutes.profilePath);
    } else if (index == 1) {
      context.go(AppRoutes.allFortunesPath);
    } else if (index == 2) {
      context.go(AppRoutes.homePath);
    } else if (index == 4) {
      context.go(AppRoutes.termsPath);
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final s = context.strings;
    final ok = await _confirmDestructive(
      context,
      title: s.historyClearTitle,
      body: s.historyClearBody,
      confirmLabel: s.historyClearConfirm,
    );
    if (ok && context.mounted) {
      await ref.read(historyControllerProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final state = ref.watch(historyControllerProvider);
    final canClear = state is HistoryLoaded && state.items.isNotEmpty;

    return FortuneScaffold(
      appBar: FortuneAppBar(
        title: Text(s.historyTitle),
        actions: [
          if (canClear)
            IconButton(
              tooltip: s.historyClearTooltip,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      // History is a destination, not a detour — it was losing the tabs
      // the moment you arrived, so the only way out was Telegram's Close.
      bottomNavigationBar: PremiumBottomNavigation(
        currentIndex: 3,
        onTap: (i) => _tapNav(context, i),
      ),
      child: switch (state) {
        HistoryLoading() => const Center(child: FortuneLoading()),
        HistoryFailed(:final failure) => FortuneErrorState(
            message: FailureMessageResolver.resolve(failure),
            reassurance: s.errorReassurance,
            retryLabel: s.actionRetry,
            onRetry: () => ref.read(historyControllerProvider.notifier).retry(),
          ),
        HistoryLoaded(:final items) when items.isEmpty => FortuneEmptyState(
            title: s.historyEmptyTitle,
            description: s.historyEmptyBody,
            actionLabel: s.historyEmptyAction,
            onAction: () => context.go(AppRoutes.allFortunesPath),
          ),
        HistoryLoaded() => _HistoryList(state: state),
      },
    );
  }
}

/// One confirmation gate for every permanent delete on this surface — a
/// clear-all or a single reading. Returns true only on an explicit yes.
Future<bool> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final s = context.strings;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.state});

  final HistoryLoaded state;

  Future<void> _confirmDeleteOne(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final s = context.strings;
    final ok = await _confirmDestructive(
      context,
      title: s.historyDeleteTitle,
      body: s.historyDeleteBody,
      confirmLabel: s.historyDeleteConfirm,
    );
    if (ok && context.mounted) {
      await ref.read(historyControllerProvider.notifier).deleteOne(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;

    // The summary sits in the first slot of the same list, so it scrolls with
    // the journal instead of pinning a panel above it (scope §6).
    const summarySlot = 1;

    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      itemCount: summarySlot + state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, slot) {
        if (slot == 0) return const HistorySummaryCard();

        final index = slot - summarySlot;
        if (index >= state.items.length) {
          // Tail slot: a quiet "more" affordance, never auto-firing spinners.
          return Center(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsetsDirectional.all(AppSpacing.sm),
                    child: FortuneLoading(),
                  )
                : FortuneButton(
                    label: s.historyLoadMore,
                    variant: FortuneButtonVariant.text,
                    fullWidth: false,
                    onPressed: () =>
                        ref.read(historyControllerProvider.notifier).loadMore(),
                  ),
          );
        }

        final reading = state.items[index];
        return FortuneFadeIn(
          duration: Duration(milliseconds: 220 + (index % 8) * 50),
          child: HistoryCard(
            reading: reading,
            onOpen: () =>
                context.push(AppRoutes.reading(reading.id), extra: reading),
            onDelete: () => _confirmDeleteOne(context, ref, reading.id),
          ),
        );
      },
    );
  }
}
