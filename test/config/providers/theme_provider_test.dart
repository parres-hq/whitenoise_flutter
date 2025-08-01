import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
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

    group('when theme mode is set in shared preferences', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.dark.index,
        });
        notifier.build();
        await Future.delayed(Duration.zero); // Wait for the load theme mode to complete
      });

      test('Initial theme mode is loaded from shared preferences', () async {
        expect(container.read(themeProvider).themeMode, ThemeMode.dark);
      });
    });

    group('setThemeMode', () {
      test('updates theme mode', () async {
        await notifier.setThemeMode(ThemeMode.dark);
        expect(container.read(themeProvider).themeMode, ThemeMode.dark);

        await notifier.setThemeMode(ThemeMode.light);
        expect(container.read(themeProvider).themeMode, ThemeMode.light);
      });
      test('saves changes to SharedPreferences', () async {
        await notifier.setThemeMode(ThemeMode.light);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
      });

      test('notifies listeners when theme changes', () async {
        addTearDown(container.dispose);

        var notificationCount = 0;
        final listener = container.listen(
          themeProvider,
          (previous, next) {
            notificationCount++;
          },
        );
        await notifier.setThemeMode(ThemeMode.dark);
        expect(notificationCount, equals(1));
        listener.close();
      });
    });

    group('toggleThemeMode', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.light.index,
        });
        notifier.build();
        await Future.delayed(Duration.zero); // Wait for the load theme mode to complete
      });
      test('toggles between light and dark', () async {
        // Toggle to dark mode
        await notifier.toggleThemeMode();
        expect(container.read(themeProvider).themeMode, ThemeMode.dark);

        // Toggle back to light mode
        await notifier.toggleThemeMode();
        expect(container.read(themeProvider).themeMode, ThemeMode.light);
      });

      test('notifies listeners when theme is toggled', () async {
        addTearDown(container.dispose);

        var notificationCount = 0;
        final listener = container.listen(
          themeProvider,
          (previous, next) {
            notificationCount++;
          },
        );
        await notifier.toggleThemeMode();
        expect(notificationCount, equals(1));
        listener.close();
      });

      group('inside a widget', () {
        Future<void> mountWidget(WidgetTester tester) async {
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
        }

        testWidgets('changes theme', (WidgetTester tester) async {
          SharedPreferences.setMockInitialValues({});
          await mountWidget(tester);

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
      });
    });
  });
}
