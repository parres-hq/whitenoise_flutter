import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocalizationService {
  static const Map<String, String> _supportedLocales = {
    'system': 'System',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
  };

  static const String _fallbackLocale = 'en';
  static Map<String, dynamic>? _localizedStrings;
  static String _currentLocale = _fallbackLocale;
  static String _selectedLocale = 'system'; // User's choice (system/manual)

  /// Get all supported locales
  static Map<String, String> get supportedLocales => _supportedLocales;

  /// Get current locale
  static String get currentLocale => _currentLocale;

  /// Get selected locale (system or specific)
  static String get selectedLocale => _selectedLocale;

  /// Get current locale as Locale object
  static Locale get currentLocaleObject => Locale(_currentLocale);

  /// Get all supported Locale objects (excluding system)
  static List<Locale> get supportedLocaleObjects =>
      _supportedLocales.keys.where((code) => code != 'system').map((code) => Locale(code)).toList();

  /// Load translations for a specific locale
  static Future<bool> load(Locale locale) async {
    String localeCode = locale.languageCode;

    // If the locale is not supported, fallback to default
    if (!_supportedLocales.containsKey(localeCode) || localeCode == 'system') {
      localeCode = _fallbackLocale;
    }

    try {
      final jsonString = await rootBundle.loadString('lib/locales/$localeCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
      _currentLocale = localeCode;
      return true;
    } catch (e) {
      // If failed to load, try fallback
      if (localeCode != _fallbackLocale) {
        return await load(const Locale(_fallbackLocale));
      }
      return false;
    }
  }

  /// Set locale preference (system or specific language)
  static Future<bool> setLocalePreference(String localeCode) async {
    _selectedLocale = localeCode;

    String actualLocale;
    if (localeCode == 'system') {
      actualLocale = getDeviceLocale();
    } else {
      actualLocale = localeCode;
    }

    return await load(Locale(actualLocale));
  }

  /// Get translated string by key path (e.g., "settings.title")
  static String translate(String key, {Map<String, dynamic>? params}) {
    if (_localizedStrings == null) {
      return key; // Return key if not loaded
    }

    // Split the key by dots to navigate nested objects
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Return key if path not found
      }
    }

    if (value is String) {
      // Handle parameter substitution
      if (params != null) {
        String result = value;
        params.forEach((paramKey, paramValue) {
          result = result.replaceAll('{$paramKey}', paramValue.toString());
        });
        return result;
      }
      return value;
    }

    return key; // Return key if value is not a string
  }

  /// Check if a key exists in the current locale
  static bool hasKey(String key) {
    if (_localizedStrings == null) return false;

    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return false;
      }
    }

    return value is String;
  }

  /// Get all keys in a section (e.g., "settings" returns all settings keys)
  static Map<String, String> getSection(String sectionKey) {
    if (_localizedStrings == null) return {};

    final keys = sectionKey.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return {};
      }
    }

    if (value is Map<String, dynamic>) {
      final Map<String, String> result = {};
      _flattenMap(value, result, '');
      return result;
    }

    return {};
  }

  /// Helper method to flatten nested maps
  static void _flattenMap(Map<String, dynamic> source, Map<String, String> target, String prefix) {
    source.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flattenMap(value, target, newKey);
      } else if (value is String) {
        target[newKey] = value;
      }
    });
  }

  /// Set locale and reload translations
  static Future<bool> setLocale(String localeCode) async {
    if (_supportedLocales.containsKey(localeCode)) {
      return await load(Locale(localeCode));
    }
    return false;
  }

  /// Get device locale or fallback
  static String getDeviceLocale() {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final localeCode = deviceLocale.languageCode;
      return _supportedLocales.containsKey(localeCode) ? localeCode : _fallbackLocale;
    } catch (e) {
      return _fallbackLocale;
    }
  }
}
