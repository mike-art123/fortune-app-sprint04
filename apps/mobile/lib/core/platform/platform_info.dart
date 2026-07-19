import 'package:flutter/foundation.dart';

/// Lightweight platform description for headers/diagnostics.
abstract final class PlatformInfo {
  static String get name {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static bool get isWeb => kIsWeb;
}
