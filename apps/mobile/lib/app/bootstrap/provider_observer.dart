import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logging/app_logger.dart';

/// Development-only provider observer (doc 51 §11.6). Values are NOT logged —
/// provider state can contain tokens and personal ritual input.
class LoggingProviderObserver extends ProviderObserver {
  const LoggingProviderObserver(this._logger);
  final AppLogger _logger;

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    _logger.debug('provider + ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _logger.debug('provider ~ ${provider.name ?? provider.runtimeType}');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    _logger.error(
      'provider ! ${provider.name ?? provider.runtimeType}',
      error: error,
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    _logger.debug('provider - ${provider.name ?? provider.runtimeType}');
  }
}
