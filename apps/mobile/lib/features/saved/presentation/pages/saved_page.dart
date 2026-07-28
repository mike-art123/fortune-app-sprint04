import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_empty_state.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../history/presentation/widgets/history_card.dart';
import '../../../reading/domain/reading.dart';
import '../../application/saved_controller.dart';

/// The readings the user has saved, newest-saved first. Each one reopens, or
/// leaves the list in one tap.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final state = ref.watch(savedControllerProvider);

    return FortuneScaffold(
      padding: EdgeInsets.zero,
      appBar: FortuneAppBar(title: Text(s.savedTitle)),
      child: switch (state) {
        SavedLoading() => const Center(child: FortuneLoading()),
        SavedFailed(:final failure) => FortuneErrorState(
            message: FailureMessageResolver.resolve(failure),
            reassurance: s.errorReassurance,
            retryLabel: s.actionRetry,
            onRetry: () => ref.read(savedControllerProvider.notifier).retry(),
          ),
        SavedLoaded(:final items) when items.isEmpty => FortuneEmptyState(
            title: s.savedEmptyTitle,
            description: s.savedEmptyBody,
          ),
        SavedLoaded(:final items) => ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _SavedCard(reading: items[i]),
          ),
      },
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.read(savedControllerProvider.notifier);
    return HistoryCard(
      reading: reading,
      onOpen: () => context.push(AppRoutes.reading(reading.id), extra: reading),
      onUnsave: () => saved.unsave(reading.id),
    );
  }
}
