import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';

void main() {
  group('WelcomeNotificationService Core Tests', () {
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
      test('should handle context clearing', () {
        // Clear context initially
        WelcomeNotificationService.clearContext();
        expect(WelcomeNotificationService.currentContext, isNull);

        // Should handle clearing when already null
        expect(() => WelcomeNotificationService.clearContext(), returnsNormally);
      });
    });

    group('Service State Management', () {
      test('should handle context operations correctly', () {
        // Clear context initially
        WelcomeNotificationService.clearContext();
        expect(WelcomeNotificationService.currentContext, isNull);

        // Multiple clears should not cause errors
        expect(() => WelcomeNotificationService.clearContext(), returnsNormally);
        expect(() => WelcomeNotificationService.clearContext(), returnsNormally);
      });
    });

    group('Provider Integration', () {
      test('should integrate with welcomes provider', () {
        final notifier = container.read(welcomesProvider.notifier);
        var callbackTriggered = false;
        WelcomeData? receivedWelcome;

        // Manually set callback to test integration
        notifier.setOnNewWelcomeCallback((welcome) {
          callbackTriggered = true;
          receivedWelcome = welcome;
        });

        // Trigger callback
        notifier.triggerWelcomeCallback(testWelcomeData);

        expect(callbackTriggered, true);
        expect(receivedWelcome, testWelcomeData);
      });

      test('should handle provider callback clearing', () {
        final notifier = container.read(welcomesProvider.notifier);
        var callbackTriggered = false;

        // Set callback
        notifier.setOnNewWelcomeCallback((welcome) {
          callbackTriggered = true;
        });

        // Clear callback
        notifier.clearOnNewWelcomeCallback();

        // Try to trigger (should not work)
        notifier.triggerWelcomeCallback(testWelcomeData);

        expect(callbackTriggered, false);
      });
    });

    group('Error Handling', () {
      test('should handle null context gracefully', () {
        // Clear context
        WelcomeNotificationService.clearContext();
        expect(WelcomeNotificationService.currentContext, isNull);

        // Should not throw errors
        expect(() => WelcomeNotificationService.clearContext(), returnsNormally);
      });
    });

    group('Callback Functionality', () {

      test('should handle callback with different welcome states', () {
        final notifier = container.read(welcomesProvider.notifier);
        var callbackCount = 0;

        notifier.setOnNewWelcomeCallback((welcome) {
          callbackCount++;
        });

        // Pending welcome should trigger callback
        notifier.triggerWelcomeCallback(testWelcomeData);
        expect(callbackCount, 1);

        // Non-pending welcome should not trigger callback
        const acceptedWelcome = WelcomeData(
          id: 'accepted_welcome',
          mlsGroupId: 'mls_group_accepted',
          nostrGroupId: 'nostr_group_accepted',
          groupName: 'Accepted Group',
          groupDescription: 'An accepted group',
          groupAdminPubkeys: ['admin_123'],
          groupRelays: ['wss://relay.com'],
          welcomer: 'welcomer_123',
          memberCount: 3,
          state: WelcomeState.accepted,
        );

        notifier.triggerWelcomeCallback(acceptedWelcome);
        expect(callbackCount, 1); // Should not increment
      });
    });
  });
}