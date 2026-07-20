import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_mode_repository.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeRepositoryProvider).read();

  Future<void> select(ThemeMode mode) async {
    await ref.read(themeModeRepositoryProvider).save(mode);
    state = mode;
  }
}

/// Overridden at bootstrap.
final themeModeRepositoryProvider = Provider<ThemeModeRepository>((ref) {
  throw UnimplementedError(
    'themeModeRepositoryProvider must be overridden at bootstrap',
  );
});

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
