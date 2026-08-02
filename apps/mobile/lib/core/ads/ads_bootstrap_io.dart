import 'dart:async';

import '../config/monetization_switch.dart';
import 'admob_service.dart';

/// Kicks off Google Mobile Ads SDK initialization at startup so the first
/// rewarded request finds a ready SDK. Fire-and-forget by design: an init
/// failure logs and retries on the first playback instead of touching
/// launch, and while monetization is paused this folds to nothing.
void warmUpAdsSdk() {
  if (!kMonetizationEnabled) return;
  unawaited(AdmobService.ensureInitialized());
}
