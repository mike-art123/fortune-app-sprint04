import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preference storage (doc 51 §25.2).
/// Features depend on this interface, never on SharedPreferences directly.
abstract interface class LocalStorage {
  String? getString(String key);
  Future<void> setString(String key, String value);
  int? getInt(String key);
  Future<void> setInt(String key, int value);
  bool? getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

class SharedPreferencesStorage implements LocalStorage {
  const SharedPreferencesStorage(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory implementation for tests.
class InMemoryStorage implements LocalStorage {
  final Map<String, Object> _map = {};
  @override
  String? getString(String key) => _map[key] as String?;
  @override
  Future<void> setString(String key, String value) async => _map[key] = value;
  @override
  int? getInt(String key) => _map[key] as int?;
  @override
  Future<void> setInt(String key, int value) async => _map[key] = value;
  @override
  bool? getBool(String key) => _map[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async => _map[key] = value;
  @override
  Future<void> remove(String key) async => _map.remove(key);
}
