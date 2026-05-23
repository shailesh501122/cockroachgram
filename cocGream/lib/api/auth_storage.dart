import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted access + refresh tokens. Backed by Keychain on iOS,
/// EncryptedSharedPreferences on Android, and the platform secure store elsewhere.
class AuthStorage {
  AuthStorage._();
  static final instance = AuthStorage._();

  static const _accessKey = 'cg.access';
  static const _refreshKey = 'cg.refresh';

  // Newer flutter_secure_storage versions migrate to custom ciphers
  // automatically — no Android-specific options needed.
  final _store = const FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    await Future.wait([
      _store.write(key: _accessKey, value: access),
      _store.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> updateAccess(String access) =>
      _store.write(key: _accessKey, value: access);

  Future<String?> readAccess() => _store.read(key: _accessKey);
  Future<String?> readRefresh() => _store.read(key: _refreshKey);

  Future<void> clear() async {
    await Future.wait([
      _store.delete(key: _accessKey),
      _store.delete(key: _refreshKey),
    ]);
  }
}
