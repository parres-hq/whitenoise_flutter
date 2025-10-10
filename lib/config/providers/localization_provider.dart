import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whitenoise/config/states/localization_state.dart';
import 'package:whitenoise/services/localization_service.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

// Localization notifier
class LocalizationNotifier extends StateNotifier<LocalizationState> {
  static const String _localeKey = 'selected_locale';

  LocalizationNotifier()
    : super(
        LocalizationState(
          currentLocale: Locale(LocalizationService.getDeviceLocale()),
        ),
      );

  /// Initialize localization on app start
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load saved locale preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_localeKey) ?? 'system';

      // Determine actual locale to load
      String actualLocale;
      if (savedLanguage == 'system') {
        actualLocale = LocalizationService.getDeviceLocale();
      } else {
        actualLocale = savedLanguage;
      }

      // Load the translations
      final success = await LocalizationService.load(Locale(actualLocale));
      if (success) {
        state = state.copyWith(
          currentLocale: Locale(actualLocale),
          selectedLanguage: savedLanguage,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load translations',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Change locale preference and save to SharedPreferences
  Future<bool> changeLocale(String languageCode) async {
    if (!LocalizationService.supportedLocales.containsKey(languageCode)) {
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Determine actual locale to load
      String actualLocale;
      if (languageCode == 'system') {
        actualLocale = LocalizationService.getDeviceLocale();
      } else {
        actualLocale = languageCode;
      }

      final success = await LocalizationService.setLocalePreference(languageCode);

      if (success) {
        // Save preference to SharedPreferences (only if not system)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localeKey, languageCode);

        state = state.copyWith(
          currentLocale: Locale(actualLocale),
          selectedLanguage: languageCode,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load locale: $languageCode',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get current locale code
  String get currentLocaleCode => state.currentLocale.languageCode;

  /// Get selected language preference
  String get selectedLanguage => state.selectedLanguage;

  /// Check if locale is supported
  bool isLocaleSupported(String localeCode) {
    return LocalizationService.supportedLocales.containsKey(localeCode);
  }

  /// Get all supported locales with their display names
  Map<String, String> get supportedLocales => LocalizationService.supportedLocales;

  /// Clear any errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Check if system language is selected
  bool get isSystemLanguage => state.selectedLanguage == 'system';

  /// Get display name for selected language
  String get selectedLanguageDisplayName {
    if (state.selectedLanguage == 'system') {
      final deviceLocale = LocalizationService.getDeviceLocale();
      final deviceLanguageName = LocalizationService.supportedLocales[deviceLocale] ?? 'English';
      return '${'shared.system'.tr()} ($deviceLanguageName)';
    }
    return LocalizationService.supportedLocales[state.selectedLanguage] ?? state.selectedLanguage;
  }
}

// Provider for localization
final localizationProvider = StateNotifierProvider<LocalizationNotifier, LocalizationState>((ref) {
  return LocalizationNotifier();
});

// Helper providers
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localizationProvider).currentLocale;
});

final selectedLanguageProvider = Provider<String>((ref) {
  return ref.watch(localizationProvider).selectedLanguage;
});

final isLocalizationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(localizationProvider).isLoading;
});

final localizationErrorProvider = Provider<String?>((ref) {
  return ref.watch(localizationProvider).error;
});
