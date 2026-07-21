import '../../core/constants/storage_keys.dart';
import '../../core/persistence/local_storage.dart';

/// Persists the user's locale choice (doc 51 §13.4).
class LocaleRepository {
  const LocaleRepository(this._storage);
  final LocalStorage _storage;

  String? read() => _storage.getString(PrefKeys.locale);
  Future<void> save(String localeCode) =>
      _storage.setString(PrefKeys.locale, localeCode);
  Future<void> reset() => _storage.remove(PrefKeys.locale);
}
