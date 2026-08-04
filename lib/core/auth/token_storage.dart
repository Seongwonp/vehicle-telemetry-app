import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<void> save(String accessToken, String refreshToken,
      [String? username]);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getUsername();
  Future<void> clear();
  Future<bool> hasToken();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  @override
  Future<void> save(String accessToken, String refreshToken,
          [String? username]) =>
      TokenStorage.save(accessToken, refreshToken, username);
  @override
  Future<String?> getToken() => TokenStorage.getToken();
  @override
  Future<String?> getRefreshToken() => TokenStorage.getRefreshToken();
  @override
  Future<String?> getUsername() => TokenStorage.getUsername();
  @override
  Future<void> clear() => TokenStorage.clear();
  @override
  Future<bool> hasToken() => TokenStorage.hasToken();
}

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
