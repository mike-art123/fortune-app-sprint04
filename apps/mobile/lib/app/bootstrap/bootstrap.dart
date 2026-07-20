import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_flavor.dart';
import '../../core/logging/app_logger.dart';
import '../app_lifecycle.dart';
import 'app_bootstrap.dart';
import 'provider_observer.dart';

/// Shared entry used by every flavor entry point (doc 51 §8).
/// Wraps startup in an error zone so a bootstrap failure shows a calm recovery
/// screen instead of a crash.
Future<void> bootstrap({
  required AppFlavor flavor,
  required Widget Function() builder,
}) async {
  await runZonedGuarded(
    () async {
      final deps = await AppBootstrap.initialise(flavor);
      final logger = ConsoleLogger(verbose: deps.config.verboseLogging);

      FlutterError.onError = (details) {
        logger.error(
          'flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        logger.error('uncaught async error', error: error, stackTrace: stack);
        return true;
      };

      final lifecycle = AppLifecycleObserver(
        (state) => logger.debug('lifecycle: ${state.name}'),
      )..attach();
      assert(lifecycle.hashCode != 0); // keep reference alive in debug

      runApp(
        ProviderScope(
          overrides: deps.overrides,
          observers: deps.config.verboseLogging ? [LoggingProviderObserver(logger)] : const [],
          child: builder(),
        ),
      );
    },
    (error, stack) {
      // Last-resort recovery: never leave the user on a black screen.
      // ignore: avoid_print
      if (kDebugMode) print('bootstrap failure: $error');
      runApp(_BootstrapFailureApp(error: error));
    },
  );
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF0E1230),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'شروع برنامه ممکن نشد',
                    style: TextStyle(color: Color(0xFFEDE8DB), fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اطلاعاتت محفوظ است. برنامه را دوباره باز کن.',
                    style: TextStyle(color: Color(0xFF9AA0B8), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  // Detail is developer-facing and shown in debug builds only.
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Color(0xFF6E748E),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
