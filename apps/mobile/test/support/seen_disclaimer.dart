import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fortune_app/core/constants/storage_keys.dart';
import 'package:fortune_app/core/persistence/local_storage.dart';
import 'package:fortune_app/shared/providers/shared_providers.dart';

/// Local storage with the first-reading disclaimer already acknowledged, so
/// ritual suites exercise the rituals themselves. The disclaimer step has its
/// own full walk-through in ritual_submission_flow_test.
Override seenDisclaimerStorage() {
  final storage = InMemoryStorage();
  unawaited(storage.setBool(PrefKeys.disclaimerSeen, true));
  return localStorageProvider.overrideWithValue(storage);
}
