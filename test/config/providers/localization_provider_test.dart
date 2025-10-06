import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/config/states/localization_state.dart';
import 'package:whitenoise/services/localization_service.dart';

void main() {
  group('LocalizationProvider Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should start with system locale', () async {
        final notifier = container.read(localizationProvider.notifier);
        await notifier.initialize();

        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'system');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('should load saved language from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'selected_locale': 'es',
        });
        container.dispose();
        container = ProviderContainer();

        final notifier = container.read(localizationProvider.notifier);
        await notifier.initialize();

        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'es');
        expect(state.currentLocale, const Locale('es'));
      });
    });

    group('changeLocale', () {
      test('should change locale to English', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('en');

        expect(success, true);
        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'en');
        expect(state.currentLocale, const Locale('en'));
      });

      test('should change locale to Spanish', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('es');

        expect(success, true);
        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'es');
        expect(state.currentLocale, const Locale('es'));
      });

      test('should change locale to German', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('de');

        expect(success, true);
        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'de');
        expect(state.currentLocale, const Locale('de'));
      });

      test('should change locale to Italian', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('it');

        expect(success, true);
        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'it');
        expect(state.currentLocale, const Locale('it'));
      });

      test('should handle system locale selection', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('es');
        expect(container.read(localizationProvider).selectedLanguage, 'es');

        final success = await notifier.changeLocale('system');

        expect(success, true);
        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'system');
      });

      test('should save language preference to SharedPreferences', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('de');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_locale'), 'de');
      });

      test('should handle loading state during locale change', () async {
        final notifier = container.read(localizationProvider.notifier);

        final future = notifier.changeLocale('es');

        await future;

        final state = container.read(localizationProvider);
        expect(state.isLoading, false);
        expect(state.selectedLanguage, 'es');
      });

      test('should notify listeners when locale changes', () async {
        final notifier = container.read(localizationProvider.notifier);
        var notificationCount = 0;

        container.listen(
          localizationProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.changeLocale('es');
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Error Handling', () {
      test('should handle unsupported locale gracefully', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('fr');

        expect(success, false);
      });

      test('should handle empty language code', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('');
        expect(success, false);
      });
    });

    group('Utility Methods', () {
      test('should return correct supported locales map', () {
        final notifier = container.read(localizationProvider.notifier);

        final supportedLocales = notifier.supportedLocales;

        expect(supportedLocales, isNotNull);
        expect(supportedLocales.keys, contains('system'));
        expect(supportedLocales.keys, contains('en'));
        expect(supportedLocales.keys, contains('es'));
        expect(supportedLocales.keys, contains('de'));
        expect(supportedLocales.keys, contains('it'));

        expect(supportedLocales['en'], 'English');
        expect(supportedLocales['es'], 'Español');
        expect(supportedLocales['de'], 'Deutsch');
        expect(supportedLocales['it'], 'Italiano');
      });

      test('should check locale support correctly', () {
        final notifier = container.read(localizationProvider.notifier);

        expect(notifier.isLocaleSupported('en'), true);
        expect(notifier.isLocaleSupported('es'), true);
        expect(notifier.isLocaleSupported('de'), true);
        expect(notifier.isLocaleSupported('it'), true);
        expect(notifier.isLocaleSupported('system'), true);
        expect(notifier.isLocaleSupported('fr'), false);
        expect(notifier.isLocaleSupported(''), false);
      });

      test('should return correct language display name', () async {
        final notifier = container.read(localizationProvider.notifier);
        await notifier.initialize();

        expect(notifier.selectedLanguageDisplayName, contains('System'));

        await notifier.changeLocale('es');
        expect(notifier.selectedLanguageDisplayName, 'Español');

        await notifier.changeLocale('de');
        expect(notifier.selectedLanguageDisplayName, 'Deutsch');

        await notifier.changeLocale('it');
        expect(notifier.selectedLanguageDisplayName, 'Italiano');
      });

      test('should clear error correctly', () async {
        final notifier = container.read(localizationProvider.notifier);

        notifier.state = notifier.state.copyWith(error: 'Test error');
        expect(container.read(localizationProvider).error, isNotNull);

        notifier.clearError();
        expect(container.read(localizationProvider).error, isNull);
      });

      test('should detect system language correctly', () async {
        final notifier = container.read(localizationProvider.notifier);
        await notifier.initialize();

        expect(notifier.isSystemLanguage, true);

        await notifier.changeLocale('en');
        expect(notifier.isSystemLanguage, false);

        await notifier.changeLocale('system');
        expect(notifier.isSystemLanguage, true);
      });
    });

    group('Provider Integration', () {
      test('should be properly registered as a Riverpod provider', () {
        expect(localizationProvider, isNotNull);

        final state = container.read(localizationProvider);
        expect(state, isNotNull);

        final notifier = container.read(localizationProvider.notifier);
        expect(notifier, isA<LocalizationNotifier>());
      });

      test('should maintain state across multiple reads', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('es');

        final state1 = container.read(localizationProvider);
        final state2 = container.read(localizationProvider);
        final state3 = container.read(localizationProvider);

        expect(state1.selectedLanguage, state2.selectedLanguage);
        expect(state2.selectedLanguage, state3.selectedLanguage);
        expect(state1.currentLocale, state2.currentLocale);
        expect(state2.currentLocale, state3.currentLocale);
      });

      test('should handle provider disposal correctly', () {
        final testContainer = ProviderContainer();

        final state = testContainer.read(localizationProvider);
        expect(state, isNotNull);

        expect(() => testContainer.dispose(), returnsNormally);
      });
    });

    group('Helper Providers', () {
      test('currentLocaleProvider should provide current locale', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('es');

        final currentLocale = container.read(currentLocaleProvider);
        expect(currentLocale, const Locale('es'));
      });

      test('selectedLanguageProvider should provide selected language', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('de');

        final selectedLanguage = container.read(selectedLanguageProvider);
        expect(selectedLanguage, 'de');
      });

      test('isLocalizationLoadingProvider should track loading state', () async {
        final notifier = container.read(localizationProvider.notifier);

        final future = notifier.changeLocale('it');

        await future;

        final isLoading = container.read(isLocalizationLoadingProvider);
        expect(isLoading, false);
      });

      test('localizationErrorProvider should provide error state', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('fr');

        final error = container.read(localizationErrorProvider);
        expect(error, isNull);

        notifier.clearError();
        final clearedError = container.read(localizationErrorProvider);
        expect(clearedError, isNull);
      });

      test('should update helper providers when locale changes', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('en');

        container.listen(
          currentLocaleProvider,
          (previous, next) {},
        );

        container.listen(
          selectedLanguageProvider,
          (previous, next) {},
        );

        await notifier.changeLocale('es');

        final currentLocale = container.read(currentLocaleProvider);
        final selectedLanguage = container.read(selectedLanguageProvider);

        expect(currentLocale, const Locale('es'));
        expect(selectedLanguage, 'es');
      });
    });

    group('State Transitions', () {
      test('should handle multiple rapid locale changes', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('en');
        await notifier.changeLocale('es');
        await notifier.changeLocale('de');
        await notifier.changeLocale('it');

        final finalState = container.read(localizationProvider);
        expect(finalState.selectedLanguage, 'it');
        expect(finalState.isLoading, false);
        expect(finalState.error, isNull);
      });

      test('should maintain state consistency during changes', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('en');
        expect(container.read(localizationProvider).selectedLanguage, 'en');

        await notifier.changeLocale('es');

        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'es');
        expect(state.currentLocale, const Locale('es'));
        expect(state.isLoading, false);
      });
    });

    group('LocalizationState', () {
      test('should implement equality correctly', () {
        final state1 = const LocalizationState(
          currentLocale: Locale('en'),
          selectedLanguage: 'en',
        );

        final state2 = const LocalizationState(
          currentLocale: Locale('en'),
          selectedLanguage: 'en',
        );

        final state3 = const LocalizationState(
          currentLocale: Locale('es'),
          selectedLanguage: 'es',
        );

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('should implement copyWith correctly', () {
        const initialState = LocalizationState(
          currentLocale: Locale('en'),
          selectedLanguage: 'en',
        );

        final copiedState = initialState.copyWith(
          selectedLanguage: 'es',
          isLoading: true,
        );

        expect(copiedState.selectedLanguage, 'es');
        expect(copiedState.isLoading, true);
        expect(copiedState.currentLocale, const Locale('en'));
        expect(copiedState.error, isNull);
      });

      test('should handle copyWith with null error', () {
        final stateWithError = const LocalizationState(
          currentLocale: Locale('en'),
          selectedLanguage: 'en',
          error: 'Some error',
        );

        final stateWithoutError = stateWithError.copyWith(error: null);

        expect(stateWithoutError.error, isNull);
        expect(stateWithoutError.selectedLanguage, 'en');
      });
    });

    group('SharedPreferences Integration', () {
      test('should persist language selection', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('de');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_locale'), 'de');

        container.dispose();
        SharedPreferences.setMockInitialValues({
          'selected_locale': 'de',
        });
        container = ProviderContainer();

        final newNotifier = container.read(localizationProvider.notifier);
        await newNotifier.initialize();

        final state = container.read(localizationProvider);
        expect(state.selectedLanguage, 'de');
      });

      test('should handle SharedPreferences errors gracefully', () async {
        final notifier = container.read(localizationProvider.notifier);

        final success = await notifier.changeLocale('es');
        expect(success, true);
      });
    });

    group('Locale Code Handling', () {
      test('should provide current locale code', () async {
        final notifier = container.read(localizationProvider.notifier);

        await notifier.changeLocale('es');
        expect(notifier.currentLocaleCode, 'es');

        await notifier.changeLocale('de');
        expect(notifier.currentLocaleCode, 'de');
      });

      test('should handle system language display correctly', () async {
        final notifier = container.read(localizationProvider.notifier);
        await notifier.initialize();

        expect(notifier.selectedLanguageDisplayName, contains('System'));

        await notifier.changeLocale('es');
        expect(notifier.selectedLanguageDisplayName, 'Español');
      });
    });

    group('Supported Locales', () {
      test('should contain all expected locales', () {
        final supportedLocales = LocalizationService.supportedLocales;

        expect(supportedLocales, contains('system'));
        expect(supportedLocales, contains('en'));
        expect(supportedLocales, contains('es'));
        expect(supportedLocales, contains('de'));
        expect(supportedLocales, contains('it'));
      });

      test('should have correct display names', () {
        final supportedLocales = LocalizationService.supportedLocales;

        expect(supportedLocales['en'], 'English');
        expect(supportedLocales['es'], 'Español');
        expect(supportedLocales['de'], 'Deutsch');
        expect(supportedLocales['it'], 'Italiano');
      });
    });

    group('System Language Detection', () {
      test('should detect device locale', () {
        final deviceLocale = LocalizationService.getDeviceLocale();
        expect(deviceLocale, isNotNull);
        expect(deviceLocale, isNotEmpty);

        final supportedCodes = ['en', 'es', 'de', 'it'];
        expect(supportedCodes, contains(deviceLocale));
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent locale changes', () async {
        final notifier = container.read(localizationProvider.notifier);

        final futures = [
          notifier.changeLocale('en'),
          notifier.changeLocale('es'),
          notifier.changeLocale('de'),
        ];

        final results = await Future.wait(futures);

        expect(results.length, 3);

        final finalState = container.read(localizationProvider);
        expect(finalState.isLoading, false);
        expect(['en', 'es', 'de'], contains(finalState.selectedLanguage));
      });
    });
  });
}
