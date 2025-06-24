import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';

void main() {
  group('ThemeNotifier Tests', () {
    late ThemeNotifier themeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeNotifier = ThemeNotifier();
    });

    test('Initial theme mode should be system', () {
      expect(themeNotifier.state.themeMode, ThemeMode.system);
    });

    test('setThemeMode should update theme mode', () async {
      await themeNotifier.setThemeMode(ThemeMode.dark);
      expect(themeNotifier.state.themeMode, ThemeMode.dark);

      await themeNotifier.setThemeMode(ThemeMode.light);
      expect(themeNotifier.state.themeMode, ThemeMode.light);
    });

    test('toggleThemeMode should toggle between light and dark', () async {
      // Start with light mode
      await themeNotifier.setThemeMode(ThemeMode.light);
      expect(themeNotifier.state.themeMode, ThemeMode.light);

      // Toggle to dark mode
      await themeNotifier.toggleThemeMode();
      expect(themeNotifier.state.themeMode, ThemeMode.dark);

      // Toggle back to light mode
      await themeNotifier.toggleThemeMode();
      expect(themeNotifier.state.themeMode, ThemeMode.light);
    });
  });

  testWidgets('Theme toggle button changes theme', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create a test app with theme provider
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final themeState = ref.watch(themeProvider);
              final themeNotifier = ref.read(themeProvider.notifier);

              return Scaffold(
                body: Column(
                  children: [
                    Text(
                      'Current theme: ${themeState.themeMode.toString()}',
                      key: const Key('themeText'),
                    ),
                    ElevatedButton(
                      key: const Key('themeButton'),
                      onPressed: () => themeNotifier.toggleThemeMode(),
                      child: const Text('Toggle Theme'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    // Verify initial theme is system
    expect(find.text('Current theme: ThemeMode.system'), findsOneWidget);

    // Tap the button to change theme
    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pump();

    // Verify theme changed to light
    expect(find.text('Current theme: ThemeMode.light'), findsOneWidget);

    // Tap again to change to dark
    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pump();

    // Verify theme changed to dark
    expect(find.text('Current theme: ThemeMode.dark'), findsOneWidget);
  });
}
