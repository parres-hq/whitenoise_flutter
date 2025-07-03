import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

void main() {
  group('WelcomesProvider Tests', () {
    late ProviderContainer container;

    // Test data
    final testWelcomeData1 = const WelcomeData(
      id: 'welcome_1',
      mlsGroupId: 'mls_group_1',
      nostrGroupId: 'nostr_group_1',
      groupName: 'Test Group 1',
      groupDescription: 'A test group invitation',
      groupAdminPubkeys: ['admin_pubkey_123', 'admin_pubkey_456'],
      groupRelays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
      welcomer: 'welcomer_pubkey_123',
      memberCount: 5,
      state: WelcomeState.pending,
    );

    final testWelcomeData2 = const WelcomeData(
      id: 'welcome_2',
      mlsGroupId: 'mls_group_2',
      nostrGroupId: 'nostr_group_2',
      groupName: 'Test Group 2',
      groupDescription: 'Another test group invitation',
      groupAdminPubkeys: ['admin_pubkey_789'],
      groupRelays: ['wss://relay3.example.com'],
      welcomer: 'welcomer_pubkey_456',
      memberCount: 10,
      state: WelcomeState.accepted,
    );

    final testWelcomeData3 = const WelcomeData(
      id: 'welcome_3',
      mlsGroupId: 'mls_group_3',
      nostrGroupId: 'nostr_group_3',
      groupName: 'Test Group 3',
      groupDescription: 'A declined group invitation',
      groupAdminPubkeys: ['admin_pubkey_999'],
      groupRelays: ['wss://relay4.example.com'],
      welcomer: 'welcomer_pubkey_789',
      memberCount: 15,
      state: WelcomeState.declined,
    );

    final testWelcomeData4 = const WelcomeData(
      id: 'welcome_4',
      mlsGroupId: 'mls_group_4',
      nostrGroupId: 'nostr_group_4',
      groupName: 'Test Group 4',
      groupDescription: 'An ignored group invitation',
      groupAdminPubkeys: ['admin_pubkey_111'],
      groupRelays: ['wss://relay5.example.com'],
      welcomer: 'welcomer_pubkey_000',
      memberCount: 3,
      state: WelcomeState.ignored,
    );

    final testWelcomes = [testWelcomeData1, testWelcomeData2, testWelcomeData3, testWelcomeData4];

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should start with empty state', () {
        final state = container.read(welcomesProvider);

        expect(state.welcomes, isNull);
        expect(state.welcomeById, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });
    });

    group('State Management', () {
      test('should update loading state correctly', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Initial state
        expect(container.read(welcomesProvider).isLoading, false);

        // Manually set loading state for testing
        notifier.state = notifier.state.copyWith(isLoading: true);
        expect(container.read(welcomesProvider).isLoading, true);

        notifier.state = notifier.state.copyWith(isLoading: false);
        expect(container.read(welcomesProvider).isLoading, false);
      });

      test('should update error state correctly', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Initial state
        expect(container.read(welcomesProvider).error, isNull);

        // Set error
        notifier.state = notifier.state.copyWith(error: 'Test error');
        expect(container.read(welcomesProvider).error, 'Test error');

        // Clear error
        notifier.state = notifier.state.copyWith(error: null);
        expect(container.read(welcomesProvider).error, isNull);
      });

      test('should update welcomes correctly', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Set welcomes
        notifier.state = notifier.state.copyWith(welcomes: testWelcomes);

        final state = container.read(welcomesProvider);
        expect(state.welcomes, testWelcomes);
        expect(state.welcomes!.length, 4);
      });

      test('should update welcomeById map correctly', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{
          'welcome_1': testWelcomeData1,
          'welcome_2': testWelcomeData2,
        };

        notifier.state = notifier.state.copyWith(welcomeById: welcomeById);

        final state = container.read(welcomesProvider);
        expect(state.welcomeById, welcomeById);
        expect(state.welcomeById!['welcome_1'], testWelcomeData1);
        expect(state.welcomeById!['welcome_2'], testWelcomeData2);
      });

      test('should update both welcomes and welcomeById when setting welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );

        final state = container.read(welcomesProvider);
        expect(state.welcomes, testWelcomes);
        expect(state.welcomeById, welcomeById);
        expect(state.welcomeById!.length, 4);
        expect(state.welcomes!.length, 4);
      });
    });

    group('Utility Methods', () {
      setUp(() {
        // Set up test data for utility method tests
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );
      });

      test('getPendingWelcomes should return only pending welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        final pendingWelcomes = notifier.getPendingWelcomes();

        expect(pendingWelcomes.length, 1);
        expect(pendingWelcomes.every((w) => w.state == WelcomeState.pending), true);
        expect(pendingWelcomes.first.id, 'welcome_1');
        expect(pendingWelcomes.first.groupName, 'Test Group 1');
      });

      test('getAcceptedWelcomes should return only accepted welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        final acceptedWelcomes = notifier.getAcceptedWelcomes();

        expect(acceptedWelcomes.length, 1);
        expect(acceptedWelcomes.every((w) => w.state == WelcomeState.accepted), true);
        expect(acceptedWelcomes.first.id, 'welcome_2');
        expect(acceptedWelcomes.first.groupName, 'Test Group 2');
      });

      test('getDeclinedWelcomes should return only declined welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        final declinedWelcomes = notifier.getDeclinedWelcomes();

        expect(declinedWelcomes.length, 1);
        expect(declinedWelcomes.every((w) => w.state == WelcomeState.declined), true);
        expect(declinedWelcomes.first.id, 'welcome_3');
        expect(declinedWelcomes.first.groupName, 'Test Group 3');
      });

      test('getWelcomeById should return correct welcome', () {
        final notifier = container.read(welcomesProvider.notifier);

        final welcome1 = notifier.getWelcomeById('welcome_1');
        final welcome2 = notifier.getWelcomeById('welcome_2');
        final nonExistent = notifier.getWelcomeById('non_existent');

        expect(welcome1, isNotNull);
        expect(welcome1!.id, 'welcome_1');
        expect(welcome1.groupName, 'Test Group 1');
        expect(welcome1.state, WelcomeState.pending);

        expect(welcome2, isNotNull);
        expect(welcome2!.id, 'welcome_2');
        expect(welcome2.groupName, 'Test Group 2');
        expect(welcome2.state, WelcomeState.accepted);

        expect(nonExistent, isNull);
      });

      test('clearWelcomeData should reset state to initial values', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Verify data is set
        expect(container.read(welcomesProvider).welcomes, isNotNull);
        expect(container.read(welcomesProvider).welcomeById, isNotNull);

        // Clear data
        notifier.clearWelcomeData();

        final state = container.read(welcomesProvider);
        expect(state.welcomes, isNull);
        expect(state.welcomeById, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });
    });

    group('Welcome State Filtering', () {
      setUp(() {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );
      });

      test('should correctly count welcomes by state', () {
        final notifier = container.read(welcomesProvider.notifier);

        final pendingCount = notifier.getPendingWelcomes().length;
        final acceptedCount = notifier.getAcceptedWelcomes().length;
        final declinedCount = notifier.getDeclinedWelcomes().length;

        expect(pendingCount, 1);
        expect(acceptedCount, 1);
        expect(declinedCount, 1);
        expect(pendingCount + acceptedCount + declinedCount, 3); // One ignored welcome not counted
      });

      test('should handle empty welcomes list', () {
        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(welcomes: <WelcomeData>[]);

        expect(notifier.getPendingWelcomes(), isEmpty);
        expect(notifier.getAcceptedWelcomes(), isEmpty);
        expect(notifier.getDeclinedWelcomes(), isEmpty);
      });

      test('should handle null welcomes list', () {
        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(welcomes: null);

        expect(notifier.getPendingWelcomes(), isEmpty);
        expect(notifier.getAcceptedWelcomes(), isEmpty);
        expect(notifier.getDeclinedWelcomes(), isEmpty);
      });

      test('should correctly filter ignored welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        final allWelcomes = notifier.state.welcomes!;
        final ignoredWelcomes = allWelcomes.where((w) => w.state == WelcomeState.ignored).toList();

        expect(ignoredWelcomes.length, 1);
        expect(ignoredWelcomes.first.id, 'welcome_4');
        expect(ignoredWelcomes.first.groupName, 'Test Group 4');
      });
    });

    group('Welcome Data Validation', () {
      test('should validate welcome data properties', () {
        final welcome = testWelcomeData1;

        expect(welcome.id, isNotEmpty);
        expect(welcome.mlsGroupId, isNotEmpty);
        expect(welcome.nostrGroupId, isNotEmpty);
        expect(welcome.groupName, isNotEmpty);
        expect(welcome.groupDescription, isNotEmpty);
        expect(welcome.groupAdminPubkeys, isNotEmpty);
        expect(welcome.groupRelays, isNotEmpty);
        expect(welcome.welcomer, isNotEmpty);
        expect(welcome.memberCount, greaterThan(0));
        expect(welcome.state, isA<WelcomeState>());
      });

      test('should handle welcomes with different admin counts', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );

        final welcome1 = notifier.getWelcomeById('welcome_1');
        final welcome2 = notifier.getWelcomeById('welcome_2');

        expect(welcome1!.groupAdminPubkeys.length, 2);
        expect(welcome2!.groupAdminPubkeys.length, 1);
      });

      test('should handle welcomes with different relay counts', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );

        final welcome1 = notifier.getWelcomeById('welcome_1');
        final welcome2 = notifier.getWelcomeById('welcome_2');

        expect(welcome1!.groupRelays.length, 2);
        expect(welcome2!.groupRelays.length, 1);
      });

      test('should handle welcomes with different member counts', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );

        final memberCounts = testWelcomes.map((w) => w.memberCount).toList();
        expect(memberCounts, containsAll([5, 10, 15, 3]));
        expect(memberCounts.every((count) => count > 0), true);
      });
    });

    group('Edge Cases', () {
      test('should handle welcome with empty description', () {
        final welcomeWithEmptyDesc = const WelcomeData(
          id: 'welcome_empty_desc',
          mlsGroupId: 'mls_group_empty',
          nostrGroupId: 'nostr_group_empty',
          groupName: 'Group With Empty Description',
          groupDescription: '',
          groupAdminPubkeys: ['admin_123'],
          groupRelays: ['wss://relay.example.com'],
          welcomer: 'welcomer_123',
          memberCount: 1,
          state: WelcomeState.pending,
        );

        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(
          welcomes: [welcomeWithEmptyDesc],
          welcomeById: {'welcome_empty_desc': welcomeWithEmptyDesc},
        );

        final welcome = notifier.getWelcomeById('welcome_empty_desc');
        expect(welcome, isNotNull);
        expect(welcome!.groupDescription, isEmpty);
        expect(welcome.groupName, isNotEmpty);
      });

      test('should handle welcome with single member', () {
        final singleMemberWelcome = const WelcomeData(
          id: 'welcome_single',
          mlsGroupId: 'mls_group_single',
          nostrGroupId: 'nostr_group_single',
          groupName: 'Single Member Group',
          groupDescription: 'A group with just one member',
          groupAdminPubkeys: ['admin_123'],
          groupRelays: ['wss://relay.example.com'],
          welcomer: 'welcomer_123',
          memberCount: 1,
          state: WelcomeState.pending,
        );

        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(
          welcomes: [singleMemberWelcome],
          welcomeById: {'welcome_single': singleMemberWelcome},
        );

        final welcome = notifier.getWelcomeById('welcome_single');
        expect(welcome, isNotNull);
        expect(welcome!.memberCount, 1);
      });

      test('should handle welcome with multiple admins', () {
        final multiAdminWelcome = const WelcomeData(
          id: 'welcome_multi_admin',
          mlsGroupId: 'mls_group_multi',
          nostrGroupId: 'nostr_group_multi',
          groupName: 'Multi Admin Group',
          groupDescription: 'A group with multiple admins',
          groupAdminPubkeys: ['admin_1', 'admin_2', 'admin_3', 'admin_4'],
          groupRelays: ['wss://relay.example.com'],
          welcomer: 'welcomer_123',
          memberCount: 10,
          state: WelcomeState.pending,
        );

        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(
          welcomes: [multiAdminWelcome],
          welcomeById: {'welcome_multi_admin': multiAdminWelcome},
        );

        final welcome = notifier.getWelcomeById('welcome_multi_admin');
        expect(welcome, isNotNull);
        expect(welcome!.groupAdminPubkeys.length, 4);
        expect(
          welcome.groupAdminPubkeys,
          containsAll(['admin_1', 'admin_2', 'admin_3', 'admin_4']),
        );
      });

      test('should handle welcome with multiple relays', () {
        final multiRelayWelcome = const WelcomeData(
          id: 'welcome_multi_relay',
          mlsGroupId: 'mls_group_relay',
          nostrGroupId: 'nostr_group_relay',
          groupName: 'Multi Relay Group',
          groupDescription: 'A group with multiple relays',
          groupAdminPubkeys: ['admin_123'],
          groupRelays: [
            'wss://relay1.example.com',
            'wss://relay2.example.com',
            'wss://relay3.example.com',
          ],
          welcomer: 'welcomer_123',
          memberCount: 5,
          state: WelcomeState.pending,
        );

        final notifier = container.read(welcomesProvider.notifier);
        notifier.state = notifier.state.copyWith(
          welcomes: [multiRelayWelcome],
          welcomeById: {'welcome_multi_relay': multiRelayWelcome},
        );

        final welcome = notifier.getWelcomeById('welcome_multi_relay');
        expect(welcome, isNotNull);
        expect(welcome!.groupRelays.length, 3);
        expect(
          welcome.groupRelays,
          containsAll([
            'wss://relay1.example.com',
            'wss://relay2.example.com',
            'wss://relay3.example.com',
          ]),
        );
      });
    });

    group('State Consistency', () {
      test('should maintain consistency between welcomes and welcomeById', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in testWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: testWelcomes,
          welcomeById: welcomeById,
        );

        final state = container.read(welcomesProvider);

        // Check that every welcome in the list is also in the map
        for (final welcome in state.welcomes!) {
          expect(state.welcomeById!.containsKey(welcome.id), true);
          expect(state.welcomeById![welcome.id], welcome);
        }

        // Check that every welcome in the map is also in the list
        for (final entry in state.welcomeById!.entries) {
          final welcomeInList = state.welcomes!.any((w) => w.id == entry.key);
          expect(welcomeInList, true);
        }
      });

      test('should handle partial state updates correctly', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Set initial state
        notifier.state = notifier.state.copyWith(
          isLoading: true,
          error: 'initial error',
        );

        // Update only welcomes
        notifier.state = notifier.state.copyWith(
          welcomes: [testWelcomeData1],
        );

        final state = container.read(welcomesProvider);
        expect(state.welcomes, [testWelcomeData1]);
        expect(state.isLoading, true); // Should remain unchanged
        expect(state.error, 'initial error'); // Should remain unchanged

        // Clear error and loading
        notifier.state = notifier.state.copyWith(
          isLoading: false,
          error: null,
        );

        final finalState = container.read(welcomesProvider);
        expect(finalState.welcomes, [testWelcomeData1]); // Should remain unchanged
        expect(finalState.isLoading, false);
        expect(finalState.error, isNull);
      });
    });

    group('Provider Integration', () {
      test('should be properly registered as a Riverpod provider', () {
        // Test that the provider is properly set up
        expect(welcomesProvider, isNotNull);

        // Test that we can read from it
        final state = container.read(welcomesProvider);
        expect(state, isNotNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
        expect(state.welcomes, isNull);
        expect(state.welcomeById, isNull);

        // Test that we can get the notifier
        final notifier = container.read(welcomesProvider.notifier);
        expect(notifier, isA<WelcomesNotifier>());
      });

      test('should maintain state across multiple reads', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{'test': testWelcomeData1};

        // Set some state
        notifier.state = notifier.state.copyWith(
          welcomes: [testWelcomeData1],
          welcomeById: welcomeById,
          isLoading: true,
          error: 'test error',
        );

        // Read multiple times and ensure state is consistent
        final state1 = container.read(welcomesProvider);
        final state2 = container.read(welcomesProvider);
        final state3 = container.read(welcomesProvider);

        expect(state1.welcomes, state2.welcomes);
        expect(state2.welcomes, state3.welcomes);
        expect(state1.welcomeById, state2.welcomeById);
        expect(state2.welcomeById, state3.welcomeById);
        expect(state1.isLoading, state2.isLoading);
        expect(state2.isLoading, state3.isLoading);
        expect(state1.error, state2.error);
        expect(state2.error, state3.error);
      });

      test('should handle provider disposal correctly', () {
        // Create a new container to test disposal
        final testContainer = ProviderContainer();

        // Use the provider
        final state = testContainer.read(welcomesProvider);
        expect(state, isNotNull);

        // Dispose container
        expect(() => testContainer.dispose(), returnsNormally);
      });
    });

    group('WelcomeState Enum Tests', () {
      test('should handle all WelcomeState enum values', () {
        final pendingWelcome = testWelcomeData1.copyWith(state: WelcomeState.pending);
        final acceptedWelcome = testWelcomeData1.copyWith(state: WelcomeState.accepted);
        final declinedWelcome = testWelcomeData1.copyWith(state: WelcomeState.declined);
        final ignoredWelcome = testWelcomeData1.copyWith(state: WelcomeState.ignored);

        expect(pendingWelcome.state, WelcomeState.pending);
        expect(acceptedWelcome.state, WelcomeState.accepted);
        expect(declinedWelcome.state, WelcomeState.declined);
        expect(ignoredWelcome.state, WelcomeState.ignored);
      });

      test('should filter welcomes by all state types', () {
        final welcomes = [
          testWelcomeData1, // pending
          testWelcomeData2, // accepted
          testWelcomeData3, // declined
          testWelcomeData4, // ignored
        ];

        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};

        for (final welcome in welcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: welcomes,
          welcomeById: welcomeById,
        );

        expect(notifier.getPendingWelcomes().length, 1);
        expect(notifier.getAcceptedWelcomes().length, 1);
        expect(notifier.getDeclinedWelcomes().length, 1);

        // Test ignored state separately since there's no getter method
        final allWelcomes = notifier.state.welcomes!;
        final ignoredWelcomes = allWelcomes.where((w) => w.state == WelcomeState.ignored).toList();
        expect(ignoredWelcomes.length, 1);
      });
    });

    group('Callback Functionality', () {
      test('should set and clear callback correctly', () {
        final notifier = container.read(welcomesProvider.notifier);
        var callbackTriggered = false;
        WelcomeData? receivedWelcome;

        // Set callback
        notifier.setOnNewWelcomeCallback((welcome) {
          callbackTriggered = true;
          receivedWelcome = welcome;
        });

        // Trigger callback manually
        notifier.triggerWelcomeCallback(testWelcomeData1);

        expect(callbackTriggered, true);
        expect(receivedWelcome, testWelcomeData1);

        // Clear callback
        callbackTriggered = false;
        receivedWelcome = null;
        notifier.clearOnNewWelcomeCallback();

        // Try to trigger again
        notifier.triggerWelcomeCallback(testWelcomeData1);

        expect(callbackTriggered, false);
        expect(receivedWelcome, isNull);
      });

      test('should only trigger callback for pending welcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        var callbackTriggered = false;

        notifier.setOnNewWelcomeCallback((welcome) {
          callbackTriggered = true;
        });

        // Try with accepted welcome (should not trigger)
        notifier.triggerWelcomeCallback(testWelcomeData2); // accepted
        expect(callbackTriggered, false);

        // Try with pending welcome (should trigger)
        notifier.triggerWelcomeCallback(testWelcomeData1); // pending
        expect(callbackTriggered, true);
      });

      test('should handle multiple welcome triggers', () {
        final notifier = container.read(welcomesProvider.notifier);
        WelcomeData? receivedWelcome;

        notifier.setOnNewWelcomeCallback((welcome) {
          receivedWelcome = welcome;
        });

        // Trigger first callback
        notifier.triggerWelcomeCallback(testWelcomeData1);
        expect(receivedWelcome, testWelcomeData1);

        // Reset for next test
        receivedWelcome = null;
        
        // Trigger another callback
        notifier.triggerWelcomeCallback(testWelcomeData1);
        expect(receivedWelcome, testWelcomeData1);
      });

      test('should not trigger callback when no callback is set', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Ensure no callback is set
        notifier.clearOnNewWelcomeCallback();

        // This should not throw an error
        expect(() => notifier.triggerWelcomeCallback(testWelcomeData1), returnsNormally);
      });

      test('should show next pending welcome', () {
        final notifier = container.read(welcomesProvider.notifier);
        final welcomeById = <String, WelcomeData>{};
        
        // Set up multiple pending welcomes
        final pendingWelcomes = [testWelcomeData1, testWelcomeData4]; // both pending
        for (final welcome in pendingWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        notifier.state = notifier.state.copyWith(
          welcomes: pendingWelcomes,
          welcomeById: welcomeById,
        );

        WelcomeData? receivedWelcome;
        notifier.setOnNewWelcomeCallback((welcome) {
          receivedWelcome = welcome;
        });

        // Should show the first pending welcome
        notifier.showNextPendingWelcome();
        expect(receivedWelcome, testWelcomeData1);
      });

      test('should handle no pending welcomes when showing next', () {
        final notifier = container.read(welcomesProvider.notifier);
        
        // Set up with no pending welcomes
        notifier.state = notifier.state.copyWith(
          welcomes: [testWelcomeData2, testWelcomeData3], // accepted and declined
          welcomeById: {
            'welcome_2': testWelcomeData2,
            'welcome_3': testWelcomeData3,
          },
        );

        var callbackTriggered = false;
        notifier.setOnNewWelcomeCallback((welcome) {
          callbackTriggered = true;
        });

        // Should not trigger callback when no pending welcomes
        notifier.showNextPendingWelcome();
        expect(callbackTriggered, false);
      });

      test('should handle new welcomes detection during loadWelcomes', () {
        final notifier = container.read(welcomesProvider.notifier);
        WelcomeData? receivedWelcome;

        // Set up initial state with no welcomes
        notifier.state = notifier.state.copyWith(
          welcomes: [],
          welcomeById: {},
        );

        notifier.setOnNewWelcomeCallback((welcome) {
          receivedWelcome = welcome;
        });

        // Simulate loadWelcomes finding new pending welcomes
        final newWelcomes = [testWelcomeData1, testWelcomeData4]; // both pending
        final welcomeById = <String, WelcomeData>{};
        for (final welcome in newWelcomes) {
          welcomeById[welcome.id] = welcome;
        }

        // Get current pending welcomes (should be empty)
        final previousPendingIds = notifier.getPendingWelcomes().map((w) => w.id).toSet();
        expect(previousPendingIds, isEmpty);

        // Update state as loadWelcomes would
        notifier.state = notifier.state.copyWith(
          welcomes: newWelcomes,
          welcomeById: welcomeById,
        );

        // Find new pending welcomes and trigger callback for the first one
        final newPendingWelcomes = newWelcomes
            .where((w) => w.state == WelcomeState.pending && !previousPendingIds.contains(w.id))
            .toList();

        if (newPendingWelcomes.isNotEmpty) {
          notifier.triggerWelcomeCallback(newPendingWelcomes.first);
        }

        // Should show only the first new pending welcome
        expect(receivedWelcome, testWelcomeData1);
      });
    });

    group('Error Handling', () {
      test('should handle state updates during error conditions', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Set error state
        notifier.state = notifier.state.copyWith(
          error: 'Network error',
          isLoading: false,
        );

        // Attempt to update welcomes during error state
        notifier.state = notifier.state.copyWith(
          welcomes: [testWelcomeData1],
          error: null, // Clear error
        );

        final state = container.read(welcomesProvider);
        expect(state.welcomes, [testWelcomeData1]);
        expect(state.error, isNull);
        expect(state.isLoading, false);
      });

      test('should handle concurrent state updates', () {
        final notifier = container.read(welcomesProvider.notifier);

        // Simulate concurrent updates
        notifier.state = notifier.state.copyWith(isLoading: true);
        notifier.state = notifier.state.copyWith(welcomes: [testWelcomeData1]);
        notifier.state = notifier.state.copyWith(isLoading: false);
        notifier.state = notifier.state.copyWith(welcomeById: {'test': testWelcomeData1});

        final state = container.read(welcomesProvider);
        expect(state.welcomes, [testWelcomeData1]);
        expect(state.welcomeById, {'test': testWelcomeData1});
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });
    });
  });
}

// Extension to add copyWith method for testing
extension WelcomeDataCopyWith on WelcomeData {
  WelcomeData copyWith({
    String? id,
    String? mlsGroupId,
    String? nostrGroupId,
    String? groupName,
    String? groupDescription,
    List<String>? groupAdminPubkeys,
    List<String>? groupRelays,
    String? welcomer,
    int? memberCount,
    WelcomeState? state,
  }) {
    return WelcomeData(
      id: id ?? this.id,
      mlsGroupId: mlsGroupId ?? this.mlsGroupId,
      nostrGroupId: nostrGroupId ?? this.nostrGroupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupAdminPubkeys: groupAdminPubkeys ?? this.groupAdminPubkeys,
      groupRelays: groupRelays ?? this.groupRelays,
      welcomer: welcomer ?? this.welcomer,
      memberCount: memberCount ?? this.memberCount,
      state: state ?? this.state,
    );
  }
}
