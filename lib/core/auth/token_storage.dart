import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';
  static const _usernameKey = 'username';

  static Future<void> save(String accessToken, String refreshToken,
      [String? username]) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    if (username != null) {
      await _storage.write(key: _usernameKey, value: username);
    }
  }

  static Future<String?> getToken() => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  static Future<String?> getUsername() => _storage.read(key: _usernameKey);

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _usernameKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null;
  }
}
