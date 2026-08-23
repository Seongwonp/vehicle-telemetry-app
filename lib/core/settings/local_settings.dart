import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalSettings {
  final FlutterSecureStorage _storage;

  const LocalSettings({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _themePreferenceKey = 'theme_preference';

  Future<String?> getThemePreference() {
    return _storage.read(key: _themePreferenceKey);
  }

  Future<void> setThemePreference(String preference) {
    return _storage.write(key: _themePreferenceKey, value: preference);
  }
}
