import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// The rewarded ad unit used when the backend's clientConfig omits one — the
/// same public identifier the backend sends. Ad unit ids ship inside every
/// APK by design; they are client identifiers, not secrets.
const String kAdmobRewardedAdUnitId = 'ca-app-pub-9505109087247499/7659183496';

/// Debug-only lifecycle logging for the whole AdMob integration.
void logAdmob(String message) {
  if (kDebugMode) debugPrint('[admob] $message');
}

/// Google Mobile Ads SDK lifecycle (the Play build only — this file is
/// reached solely through `dart.library.io` resolutions, so a web build
/// never compiles it and the paused build tree-shakes it away).
abstract final class AdmobService {
  static Future<void>? _initialization;

  /// Idempotent and safe to fire-and-forget: the first caller starts SDK
  /// initialization, later callers await the same future, and a failure
  /// resets the memo so the next attempt retries. Never throws.
  static Future<void> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      logAdmob('initializing Google Mobile Ads SDK');
      await MobileAds.instance.initialize();
      logAdmob('SDK initialized');
    } catch (error) {
      logAdmob('SDK initialization failed: $error');
      _initialization = null;
    }
  }
}
