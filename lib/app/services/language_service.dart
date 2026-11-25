import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LanguageService {
  static final _box = GetStorage();
  static const _key = 'appLanguage';
  static final ValueNotifier<Locale> languageNotifier = ValueNotifier<Locale>(getLocale());

  // Supported languages (Total 4: English, Arabic, Kurdish Sorani, Turkish)
  static const Map<String, Locale> supportedLanguages = {
    'English': Locale('en', 'US'),
    'Arabic': Locale('ar', 'IQ'),
    'Kurdish': Locale('ku', 'IQ'),
    'Turkish': Locale('tr', 'TR'),
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

  static bool get isArabic => languageNotifier.value.languageCode == 'ar';
  static bool get isKurdish => languageNotifier.value.languageCode == 'ku';
  static bool get isTurkish => languageNotifier.value.languageCode == 'tr';
  static bool get isRTL => isArabic || isKurdish;

  static String tr(String en, String ar, String ku, String trText) {
    final code = languageNotifier.value.languageCode;
    if (code == 'ar') return ar;
    if (code == 'ku') return ku;
    if (code == 'tr') return trText;
    return en;
  }

  static List<String> getAvailableLanguages() {
    return supportedLanguages.keys.toList();
  }
}

