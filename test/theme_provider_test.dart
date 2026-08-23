import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/settings/local_settings.dart';
import 'package:telemetrix/core/theme/theme_provider.dart';

class MemoryLocalSettings extends LocalSettings {
  String? value;

  MemoryLocalSettings([this.value]);

  @override
  Future<String?> getThemePreference() async => value;

  @override
  Future<void> setThemePreference(String preference) async {
    value = preference;
  }
}

void main() {
  test('저장된 테마를 복원하고 변경값을 다시 저장한다', () async {
    final settings = MemoryLocalSettings('dark');
    final notifier = ThemePreferenceNotifier(settings);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state, AppThemePreference.dark);
    expect(notifier.state.themeMode, ThemeMode.dark);

    await notifier.setPreference(AppThemePreference.light);
    expect(notifier.state, AppThemePreference.light);
    expect(settings.value, 'light');
  });

  test('알 수 없는 저장값은 시스템 모드로 복구한다', () async {
    final notifier = ThemePreferenceNotifier(MemoryLocalSettings('unknown'));
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state, AppThemePreference.system);
    expect(notifier.state.themeMode, ThemeMode.system);
  });
}
