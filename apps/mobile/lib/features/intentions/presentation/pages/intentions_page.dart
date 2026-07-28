import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../core/errors/failure_message_resolver.dart';
import '../../../../design_system/components/fortune_app_bar.dart';
import '../../../../design_system/components/fortune_empty_state.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../application/intentions_controller.dart';
import '../widgets/intention_card.dart';

/// The intentions the user has whispered before their readings, newest first.
class IntentionsPage extends ConsumerWidget {
  const IntentionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final state = ref.watch(intentionsControllerProvider);

    return FortuneScaffold(
      padding: EdgeInsets.zero,
      appBar: FortuneAppBar(title: Text(s.intentionsTitle)),
      child: switch (state) {
        IntentionsLoading() => const Center(child: FortuneLoading()),
        IntentionsFailed(:final failure) => FortuneErrorState(
            message: FailureMessageResolver.resolve(failure),
            reassurance: s.errorReassurance,
            retryLabel: s.actionRetry,
            onRetry: () =>
                ref.read(intentionsControllerProvider.notifier).retry(),
          ),
        IntentionsLoaded(:final items) when items.isEmpty => FortuneEmptyState(
            title: s.intentionsEmptyTitle,
            description: s.intentionsEmptyBody,
          ),
        IntentionsLoaded(:final items) => ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => IntentionCard(intention: items[i]),
          ),
      },
    );
  }
}
