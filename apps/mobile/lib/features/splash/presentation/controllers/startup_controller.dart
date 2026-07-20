import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_startup_state.dart';
import '../../../../core/analytics/analytics_event.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../../shared/providers/shared_providers.dart';

/// Performs foundation-only startup work (doc 51 §42):
/// config and preferences are already initialised at bootstrap, so this simply
/// runs storage migrations and reports readiness. It never fetches product
/// content and never blocks launch on analytics/crash reporting.
class StartupController extends AsyncNotifier<AppStartupState> {
  @override
  Future<AppStartupState> build() async {
    try {
      await ref.read(storageMigrationsProvider).run();

      // Sprint 04: establish the session before first navigation. A failed
      // login is a calm, valid outcome (Unauthenticated) — never a crash.
      await ref.read(authControllerProvider.notifier).bootstrap();

      // Fire-and-forget: telemetry failures must not affect startup.
      unawaited(ref.read(analyticsServiceProvider).track(const AppStarted()));

      return const StartupReady();
    } catch (e, st) {
      ref.read(appLoggerProvider).error('startup failed', error: e, stackTrace: st);
      unawaited(
        ref.read(crashReportingServiceProvider).recordError(e, st, fatal: false),
      );
      unawaited(
        ref.read(analyticsServiceProvider).track(BootstrapFailed(e.runtimeType.toString())),
      );
      return StartupFailed(e.runtimeType.toString());
    }
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(storageMigrationsProvider).run();
      await ref.read(authControllerProvider.notifier).bootstrap();
      return const StartupReady();
    });
  }
}

final startupControllerProvider = AsyncNotifierProvider<StartupController, AppStartupState>(
  StartupController.new,
);

/// Local helper so we don't pull in dart:async just for this.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
