import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LanguageService {
  static final _box = GetStorage();
  static const _key = 'appLanguage';
  static final ValueNotifier<Locale> languageNotifier = ValueNotifier<Locale>(getLocale());

  // Supported languages
  static const Map<String, Locale> supportedLanguages = {
    'English': Locale('en', 'US'),
    'Arabic': Locale('ar', 'IQ'),
    'Kurdish': Locale('ku', 'IQ'),
  };

  static Locale getLocale() {
    final stored = _box.read(_key) ?? 'English';
    return supportedLanguages[stored] ?? supportedLanguages['English']!;
  }

  static String getLanguageName() {
    return _box.read(_key) ?? 'English';
  }

  static void setLanguage(String languageName) {
    if (supportedLanguages.containsKey(languageName)) {
      _box.write(_key, languageName);
      languageNotifier.value = supportedLanguages[languageName]!;
    }
  }

  static List<String> getAvailableLanguages() {
    return supportedLanguages.keys.toList();
  }
}

