import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/config/states/localization_state.dart';
import 'package:whitenoise/services/localization_service.dart';
import 'package:whitenoise/ui/widgets/language_selector_dropdown.dart';

/// ------------------------------------------------------------------
/// Fake notifier that we use ONLY in tests
/// It extends your real LocalizationNotifier, so the provider type matches.
/// ------------------------------------------------------------------
class FakeLocalizationNotifier extends LocalizationNotifier {
  FakeLocalizationNotifier({
    required String initialSelectedLanguage,
    Map<String, String>? supported,
  }) : _supportedLocales = supported ?? LocalizationService.supportedLocales {
    final deviceLocaleCode = LocalizationService.getDeviceLocale();

    state = LocalizationState(
      currentLocale: Locale(
        initialSelectedLanguage == 'system' ? deviceLocaleCode : initialSelectedLanguage,
      ),
      selectedLanguage: initialSelectedLanguage,
    );
  }

  final Map<String, String> _supportedLocales;

  String? lastChangedLocale;
  int changeLocaleCallCount = 0;

  @override
  Map<String, String> get supportedLocales => _supportedLocales;

  @override
  Future<bool> changeLocale(String localeCode) async {
    changeLocaleCallCount++;
    lastChangedLocale = localeCode;

    final deviceLocaleCode = LocalizationService.getDeviceLocale();

    state = state.copyWith(
      selectedLanguage: localeCode,
      currentLocale: Locale(
        localeCode == 'system' ? deviceLocaleCode : localeCode,
      ),
      isLoading: false,
      error: null,
    );

    // Always report success in the fake
    return true;
  }
}

/// ------------------------------------------------------------------
/// Test wrapper that sets up ProviderScope + ScreenUtil + MaterialApp
/// and overrides `localizationProvider` with our FakeLocalizationNotifier.
/// ------------------------------------------------------------------
class WidgetTestHelper extends StatelessWidget {
  final Widget child;
  final FakeLocalizationNotifier fakeNotifier;

  const WidgetTestHelper({
    super.key,
    required this.child,
    required this.fakeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        localizationProvider.overrideWith((ref) => fakeNotifier),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) {
          return MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationService.resetDeviceLocaleOverride();
  });

  group('LanguageSelectorDropdown', () {
    testWidgets(
      'header shows "System (English)" when selectedLanguage is system and device locale is en',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        LocalizationService.setDeviceLocaleOverrideForTest(const Locale('en'));

        await LocalizationService.load(const Locale('en'));

        final fakeNotifier = FakeLocalizationNotifier(
          initialSelectedLanguage: 'system',
        );

        await tester.pumpWidget(
          WidgetTestHelper(
            fakeNotifier: fakeNotifier,
            child: const LanguageSelectorDropdown(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('System (English)'), findsOneWidget);
      },
    );
    testWidgets(
      'after selecting Deutsch, the first option still represents the system language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        LocalizationService.setDeviceLocaleOverrideForTest(const Locale('en'));

        final fakeNotifier = FakeLocalizationNotifier(
          initialSelectedLanguage: 'system',
          supported: const {
            'system': 'System',
            'en': 'English',
            'de': 'Deutsch',
          },
        );

        await tester.pumpWidget(
          WidgetTestHelper(
            fakeNotifier: fakeNotifier,
            child: const LanguageSelectorDropdown(),
          ),
        );
        await tester.pumpAndSettle();

        // Open dropdown
        await tester.tap(find.text('System (English)'));
        await tester.pumpAndSettle();

        // Select Deutsch
        await tester.tap(find.text('Deutsch'));
        await tester.pumpAndSettle();

        // Header is Deutsch now
        expect(find.text('Deutsch'), findsOneWidget);

        // Re-open
        await tester.tap(find.text('Deutsch'));
        await tester.pumpAndSettle();

        // We still see "System" entry as first system option
        expect(find.text('System'), findsOneWidget);
        // And "English" & "Deutsch" as regular entries
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Deutsch'), findsNWidgets(2)); // header + option
      },
    );
    testWidgets(
      'system label adapts when device locale is German',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Pretend system is German
        LocalizationService.setDeviceLocaleOverrideForTest(const Locale('de'));

        final fakeNotifier = FakeLocalizationNotifier(
          initialSelectedLanguage: 'system',
        );

        await tester.pumpWidget(
          WidgetTestHelper(
            fakeNotifier: fakeNotifier,
            child: const LanguageSelectorDropdown(),
          ),
        );
        await tester.pumpAndSettle();

        // Header uses toLanguageDisplayText() → "System (Deutsch)"
        expect(find.text('System (Deutsch)'), findsOneWidget);
      },
    );
  });
}
