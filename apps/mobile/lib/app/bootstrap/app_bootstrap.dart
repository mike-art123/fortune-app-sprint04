import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_flavor.dart';
import '../../core/config/environment_loader.dart';
import '../../core/persistence/local_storage.dart';
import '../../core/persistence/secure_storage.dart';
import '../../shared/providers/shared_providers.dart';
import '../localization/locale_controller.dart';
import '../localization/locale_repository.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_mode_repository.dart';

/// Result of async initialisation, used to build provider overrides.
class BootstrapDependencies {
  const BootstrapDependencies({
    required this.config,
    required this.localStorage,
    required this.secureStorage,
  });

  final AppConfig config;
  final LocalStorage localStorage;
  final SecureStorage secureStorage;

  List<Override> get overrides => [
        appConfigProvider.overrideWithValue(config),
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(secureStorage),
        localeRepositoryProvider.overrideWithValue(LocaleRepository(localStorage)),
        themeModeRepositoryProvider.overrideWithValue(ThemeModeRepository(localStorage)),
      ];
}

/// Initialises everything the app needs before the first frame (doc 51 §8).
/// Deliberately does no feature networking.
abstract final class AppBootstrap {
  static Future<BootstrapDependencies> initialise(AppFlavor flavor) async {
    WidgetsFlutterBinding.ensureInitialized();

    final config = EnvironmentLoader.load(flavor);
    final prefs = await SharedPreferences.getInstance();

    return BootstrapDependencies(
      config: config,
      localStorage: SharedPreferencesStorage(prefs),
      secureStorage: const FlutterSecureStorageAdapter(FlutterSecureStorage()),
    );
  }
}
