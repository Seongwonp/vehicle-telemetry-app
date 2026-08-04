import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 알림 on/off처럼 기기에만 남기면 되는 가벼운 설정값 저장소.
// shared_preferences를 새로 추가하는 대신, 이미 쓰고 있는
// flutter_secure_storage를 재사용한다.
class LocalSettings {
  static const _storage = FlutterSecureStorage();
  static const _notificationsKey = 'notifications_enabled';

  static Future<bool> getNotificationsEnabled() async {
    final value = await _storage.read(key: _notificationsKey);
    return value != 'false';
  }

  static Future<void> setNotificationsEnabled(bool enabled) {
    return _storage.write(key: _notificationsKey, value: enabled.toString());
  }
}
