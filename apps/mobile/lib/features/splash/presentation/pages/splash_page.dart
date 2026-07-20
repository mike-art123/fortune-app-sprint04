import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_startup_state.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../design_system/components/fortune_error_state.dart';
import '../../../../design_system/components/fortune_loading.dart';
import '../../../../design_system/components/fortune_scaffold.dart';
import '../controllers/startup_controller.dart';

/// Holds the user for the brief moment startup takes, and offers a calm
/// recovery path if it fails. No product content is fetched here.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final startup = ref.watch(startupControllerProvider);

    return FortuneScaffold(
      child: startup.when(
        loading: () => FortuneLoading(message: s.splashPreparing),
        error: (_, __) => FortuneErrorState(
          message: s.startupFailedTitle,
          reassurance: s.startupFailedBody,
          retryLabel: s.actionRetry,
          onRetry: () => ref.read(startupControllerProvider.notifier).retry(),
        ),
        data: (state) => switch (state) {
          StartupFailed() => FortuneErrorState(
            message: s.startupFailedTitle,
            reassurance: s.startupFailedBody,
            retryLabel: s.actionRetry,
            onRetry: () => ref.read(startupControllerProvider.notifier).retry(),
          ),
          _ => FortuneLoading(message: s.splashPreparing),
        },
      ),
    );
  }
}
