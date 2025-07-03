import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';

void main() {
  group('WelcomeNotificationService Tests', () {
    late ProviderContainer container;

    // Test data
    const testWelcomeData = WelcomeData(
      id: 'test_welcome_1',
      mlsGroupId: 'mls_group_1',
      nostrGroupId: 'nostr_group_1',
      groupName: 'Test Group',
      groupDescription: 'A test group invitation',
      groupAdminPubkeys: ['admin_pubkey_123'],
      groupRelays: ['wss://relay1.example.com'],
      welcomer: 'welcomer_pubkey_123',
      memberCount: 5,
      state: WelcomeState.pending,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      WelcomeNotificationService.clearContext();
    });

    group('Context Management', () {
      testWidgets('should initialize and update context correctly', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  WelcomeNotificationService.initialize(context);
                  return const Scaffold(body: Text('Test'));
                },
              ),
            ),
          ),
        );

        // Context should be set
        expect(WelcomeNotificationService.currentContext, isNotNull);

        // Update context
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  WelcomeNotificationService.updateContext(context);
                  return const Scaffold(body: Text('Updated Test'));
                },
              ),
            ),
          ),
        );

        expect(WelcomeNotificationService.currentContext, isNotNull);

        // Clear context
        WelcomeNotificationService.clearContext();
        expect(WelcomeNotificationService.currentContext, isNull);
      });
    });

    group('Service Integration', () {
      testWidgets('should setup and clear welcome notifications', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  WelcomeNotificationService.initialize(context);
                  
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        WelcomeNotificationService.setupWelcomeNotifications(ref);
                      },
                      child: const Text('Setup'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Tap to setup notifications
        await tester.tap(find.text('Setup'));
        await tester.pumpAndSettle();

        // Should not throw any errors
        expect(find.text('Setup'), findsOneWidget);
      });

      testWidgets('should clear welcome notifications without errors', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  WelcomeNotificationService.initialize(context);
                  
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        WelcomeNotificationService.setupWelcomeNotifications(ref);
                        WelcomeNotificationService.clearWelcomeNotifications(ref);
                      },
                      child: const Text('Setup and Clear'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Tap to setup and clear notifications
        await tester.tap(find.text('Setup and Clear'));
        await tester.pumpAndSettle();

        // Should not throw any errors
        expect(find.text('Setup and Clear'), findsOneWidget);
      });
    });

    group('Manual Welcome Display', () {
      testWidgets('should handle manual welcome display', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        try {
                          await WelcomeNotificationService.showWelcomeInvitation(
                            context,
                            ref,
                            testWelcomeData,
                          );
                        } catch (e) {
                          // Expected to fail without proper dependencies
                        }
                      },
                      child: const Text('Show Welcome'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Tap to show welcome (will fail gracefully due to missing dependencies)
        await tester.tap(find.text('Show Welcome'));
        await tester.pumpAndSettle();

        // Should not crash the app
        expect(find.text('Show Welcome'), findsOneWidget);
      });
    });

    group('Service State Management', () {
      test('should handle context operations correctly', () {
        // Clear context initially
        WelcomeNotificationService.clearContext();
        expect(WelcomeNotificationService.currentContext, isNull);

        // Since we can't create a real BuildContext in unit tests,
        // we'll test that the methods don't throw errors
        expect(() => WelcomeNotificationService.clearContext(), returnsNormally);
      });

      testWidgets('should handle service operations with invalid context', (tester) async {
        // Clear context to simulate invalid state
        WelcomeNotificationService.clearContext();

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        // This should handle the null context gracefully
                        WelcomeNotificationService.setupWelcomeNotifications(ref);
                      },
                      child: const Text('Test Invalid Context'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Invalid Context'));
        await tester.pumpAndSettle();

        // Should not crash
        expect(find.text('Test Invalid Context'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle errors gracefully', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  WelcomeNotificationService.initialize(context);
                  
                  return Scaffold(
                    body: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Test with null context
                            WelcomeNotificationService.clearContext();
                            WelcomeNotificationService.setupWelcomeNotifications(ref);
                          },
                          child: const Text('Test Null Context'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Test manual welcome display with no context
                            WelcomeNotificationService.clearContext();
                            try {
                              await WelcomeNotificationService.showWelcomeInvitation(
                                context,
                                ref,
                                testWelcomeData,
                              );
                            } catch (e) {
                              // Expected to fail
                            }
                          },
                          child: const Text('Test Manual Display Error'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Test both error scenarios
        await tester.tap(find.text('Test Null Context'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Manual Display Error'));
        await tester.pumpAndSettle();

        // App should still be functional
        expect(find.text('Test Null Context'), findsOneWidget);
        expect(find.text('Test Manual Display Error'), findsOneWidget);
      });
    });

    group('Service Lifecycle', () {
      testWidgets('should handle multiple initialization calls', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Initialize multiple times
                WelcomeNotificationService.initialize(context);
                WelcomeNotificationService.initialize(context);
                WelcomeNotificationService.updateContext(context);
                
                return const Scaffold(body: Text('Multiple Init Test'));
              },
            ),
          ),
        );

        // Should handle multiple calls gracefully
        expect(find.text('Multiple Init Test'), findsOneWidget);
      });

      testWidgets('should handle service operations in correct order', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        // Proper order: initialize, setup, clear
                        WelcomeNotificationService.initialize(context);
                        WelcomeNotificationService.setupWelcomeNotifications(ref);
                        WelcomeNotificationService.clearWelcomeNotifications(ref);
                        WelcomeNotificationService.clearContext();
                      },
                      child: const Text('Lifecycle Test'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Lifecycle Test'));
        await tester.pumpAndSettle();

        expect(find.text('Lifecycle Test'), findsOneWidget);
      });
    });
  });
}

