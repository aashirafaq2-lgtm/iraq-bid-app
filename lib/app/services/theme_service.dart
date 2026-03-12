import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  static final _box = GetStorage();
  static const _key = 'themeMode';
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(getThemeMode());

  static ThemeMode getThemeMode() {
    var stored = _box.read(_key);
    if (stored == null) {
      // Auto-detect system theme
      return ThemeMode.system;
    }
    return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static void setThemeMode(ThemeMode mode) {
    String? modeString;
    if (mode == ThemeMode.dark) {
      modeString = 'dark';
    } else if (mode == ThemeMode.light) {
      modeString = 'light';
    } else {
      modeString = 'system';
    }
    _box.write(_key, modeString);
    themeNotifier.value = mode;
  }

  static void toggleTheme() {
    final current = themeNotifier.value;
    if (current == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (current == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      // If system, toggle to light
      setThemeMode(ThemeMode.light);
    }
  }

  static Brightness getCurrentBrightness(BuildContext context) {
    final mode = themeNotifier.value;
    if (mode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }
}

