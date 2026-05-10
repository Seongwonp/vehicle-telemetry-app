import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'jwt_token';

  static Future<void> save(String token) =>
      _storage.write(key: _key, value: token);

  static Future<String?> getToken() => _storage.read(key: _key);

  static Future<void> clear() => _storage.delete(key: _key);

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null;
  }
}
