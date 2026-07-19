import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import 'local_storage.dart';

/// Versioned preference migrations (doc 51 §25.4). Minimal now, but the
/// contract exists so future schema changes never corrupt user settings.
class StorageMigrations {
  const StorageMigrations(this._storage);
  final LocalStorage _storage;

  Future<void> run() async {
    final current = _storage.getInt(PrefKeys.storageVersion) ?? 0;
    if (current >= AppConstants.storageVersion) return;
    // v0 -> v1: first versioned baseline; nothing to transform.
    // v1 -> v2 (Sprint 04): real auth replaced the anonymous identity anchor;
    // the stored anon id is deleted so no stale identity lingers on-device.
    if (current < 2) {
      await _storage.remove(PrefKeys.anonId);
    }
    await _storage.setInt(PrefKeys.storageVersion, AppConstants.storageVersion);
  }
}
