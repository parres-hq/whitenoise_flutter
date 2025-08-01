import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';

void main() {
  group('ThemeNotifier Tests', () {
    late ProviderContainer container;
    late ThemeNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(themeProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial theme mode should be system', () {
      final state = container.read(themeProvider);
      expect(state.themeMode, ThemeMode.system);
    });

    test('setThemeMode should update theme mode', () async {
      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeProvider).themeMode, ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeProvider).themeMode, ThemeMode.light);
    });

    test('toggleThemeMode should toggle between light and dark', () async {
      // Start with light mode
      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeProvider).themeMode, ThemeMode.light);

      // Toggle to dark mode
      await notifier.toggleThemeMode();
      expect(container.read(themeProvider).themeMode, ThemeMode.dark);

      // Toggle back to light mode
      await notifier.toggleThemeMode();
      expect(container.read(themeProvider).themeMode, ThemeMode.light);
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
