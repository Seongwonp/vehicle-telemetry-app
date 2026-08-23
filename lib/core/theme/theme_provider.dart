import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/local_settings.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceMode on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
}

final localSettingsProvider =
    Provider<LocalSettings>((ref) => const LocalSettings());

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, AppThemePreference>((ref) {
  return ThemePreferenceNotifier(ref.watch(localSettingsProvider));
});

class ThemePreferenceNotifier extends StateNotifier<AppThemePreference> {
  final LocalSettings _settings;
  var _revision = 0;

  ThemePreferenceNotifier(this._settings) : super(AppThemePreference.system) {
    _load();
  }

  Future<void> _load() async {
    final revision = _revision;
    final saved = await _settings.getThemePreference();
    if (!mounted || revision != _revision) return;
    state = AppThemePreference.values.firstWhere(
      (preference) => preference.name == saved,
      orElse: () => AppThemePreference.system,
    );
  }

  Future<void> setPreference(AppThemePreference preference) async {
    _revision++;
    state = preference;
    await _settings.setThemePreference(preference.name);
  }
}
