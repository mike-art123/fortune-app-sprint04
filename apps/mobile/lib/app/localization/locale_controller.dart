import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_repository.dart';
import 'supported_locales.dart';

/// Owns the active locale: stored preference → system → Persian default.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final repo = ref.watch(localeRepositoryProvider);
    final system = WidgetsBinding.instance.platformDispatcher.locales.firstOrNull;
    return SupportedLocales.resolve(repo.read(), system);
  }

  Future<void> select(Locale locale) async {
    await ref.read(localeRepositoryProvider).save(locale.languageCode);
    state = locale;
  }

  Future<void> resetToSystem() async {
    await ref.read(localeRepositoryProvider).reset();
    final system = WidgetsBinding.instance.platformDispatcher.locales.firstOrNull;
    state = SupportedLocales.resolve(null, system);
  }
}

/// Overridden at bootstrap with the initialised storage instance.
final localeRepositoryProvider = Provider<LocaleRepository>((ref) {
  throw UnimplementedError('localeRepositoryProvider must be overridden at bootstrap');
});

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
