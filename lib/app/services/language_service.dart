import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';

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

  static final Map<String, String> _translationCache = {};
  static final Dio _transDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)));

  /// Dynamically translates any product title or description into the active language (en, ar, ckb, tr)
  static Future<String> translateDynamic(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    final code = languageNotifier.value.languageCode;
    if (code == 'en') return text;

    final targetLang = code == 'ku' ? 'ckb' : code; // Kurdish Sorani = ckb
    final cacheKey = '${targetLang}_$trimmed';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    final stored = _box.read('tr_$cacheKey');
    if (stored is String && stored.isNotEmpty) {
      _translationCache[cacheKey] = stored;
      return stored;
    }

    try {
      final res = await _transDio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {'client': 'gtx', 'sl': 'auto', 'tl': targetLang, 'dt': 't', 'q': trimmed},
      );
      if (res.data is List && (res.data as List).isNotEmpty && res.data[0] is List) {
        final translated = (res.data[0] as List).map((e) => e[0]?.toString() ?? '').join('');
        if (translated.isNotEmpty) {
          _translationCache[cacheKey] = translated;
          _box.write('tr_$cacheKey', translated);
          return translated;
        }
      }
    } catch (_) {}
    return text;
  }
}

