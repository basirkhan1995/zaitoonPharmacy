import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStore {
  // 9.x: encrypted storage is the default; no AndroidOptions needed.
  static const _storage = FlutterSecureStorage();

  static const _kUsername = 'remember_username';
  static const _kPassword = 'remember_password';

  static Future<void> save({
    required String username,
    required String password,
    required bool remember,
  }) async {
    await _storage.write(key: _kUsername, value: username);
    if (remember) {
      await _storage.write(key: _kPassword, value: password);
    } else {
      await _storage.delete(key: _kPassword);
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kPassword);
  }

  static Future<({String? username, String? password})> load() async {
    final u = await _storage.read(key: _kUsername);
    final p = await _storage.read(key: _kPassword);
    return (username: u, password: p);
  }
}