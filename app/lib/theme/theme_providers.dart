import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/platform_storage.dart';

const _kThemeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.initial);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await PlatformStorage.write(
        key: _kThemeModeKey, value: mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ThemeMode.dark);
});

Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final saved = await PlatformStorage.read(key: _kThemeModeKey);
    if (saved == 'light') return ThemeMode.light;
  } catch (_) {}
  return ThemeMode.dark;
}
