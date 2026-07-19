import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// Secure credential storage (doc 51 §25.1). Tokens MUST NOT go to preferences.
abstract interface class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class FlutterSecureStorageAdapter implements SecureStorage {
  const FlutterSecureStorageAdapter(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<void> clear() => _storage.deleteAll();
}

/// Token-specific facade so features never juggle raw keys.
class TokenStore {
  const TokenStore(this._storage);
  final SecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(SecureKeys.accessToken);
  Future<String?> readRefreshToken() => _storage.read(SecureKeys.refreshToken);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(SecureKeys.accessToken, access);
    await _storage.write(SecureKeys.refreshToken, refresh);
  }

  /// Sprint 04: the backend issues a single access token (no refresh token
  /// yet) — expiry simply triggers a fresh Telegram login.
  Future<void> saveAccessToken(String access) =>
      _storage.write(SecureKeys.accessToken, access);

  Future<void> clear() async {
    await _storage.delete(SecureKeys.accessToken);
    await _storage.delete(SecureKeys.refreshToken);
  }
}
