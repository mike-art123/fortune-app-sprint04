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
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/motion/fortune_fade_transition.dart';
import '../../application/history_controller.dart';
import '../widgets/history_card.dart';

/// The journal — every reading the user has received, newest first.
/// Calm surface: a stale page or failed load never scolds the user.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final state = ref.watch(historyControllerProvider);

    return FortuneScaffold(
      appBar: AppBar(title: Text(s.historyTitle)),
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
            onAction: () => context.go(AppRoutes.explorePath),
          ),
        HistoryLoaded() => _HistoryList(state: state),
      },
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.state});

  final HistoryLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;

    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
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
          ),
        );
      },
    );
  }
}
