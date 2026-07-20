import 'package:flutter/material.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/persistence/local_storage.dart';

/// Persists theme preference (doc 51 §43).
class ThemeModeRepository {
  const ThemeModeRepository(this._storage);
  final LocalStorage _storage;

  ThemeMode read() => switch (_storage.getString(PrefKeys.themeMode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark, // product launches dark-first
  };

  Future<void> save(ThemeMode mode) =>
      _storage.setString(PrefKeys.themeMode, mode.name);
}
