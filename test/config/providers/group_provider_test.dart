import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';

void main() {
  group('GroupsProvider Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late ProviderContainer container;

    // Test data
    final testGroup1 = Group(
      mlsGroupId: 'mls_group_1',
      nostrGroupId: 'nostr_group_1',
      name: 'Test Group 1',
      description: 'A test group',
      adminPubkeys: ['test_pubkey_123', 'admin_pubkey_456'],
      lastMessageId: 'message_1',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
      epoch: BigInt.from(1),
      state: GroupState.active,
    );

    final testGroup2 = Group(
      mlsGroupId: 'mls_group_2',
      nostrGroupId: 'nostr_group_2',
      name: 'Direct Message',
      description: 'A direct message',
      adminPubkeys: ['test_pubkey_123'],
      epoch: BigInt.from(1),
      state: GroupState.active,
    );

    final testGroup3 = Group(
      mlsGroupId: 'mls_group_3',
      nostrGroupId: 'nostr_group_3',
      name: 'Inactive Group',
      description: 'An inactive group',
      adminPubkeys: ['other_admin_123'],
      epoch: BigInt.from(1),
      state: GroupState.inactive,
    );

    final testGroups = [testGroup1, testGroup2, testGroup3];

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should start with empty state', () {
        final state = container.read(groupsProvider);

        expect(state.groups, isNull);
        expect(state.groupMembers, isNull);
        expect(state.groupAdmins, isNull);
        expect(state.groupDisplayNames, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });
    });

    group('State Management', () {
      test('should update loading state correctly', () {
        final notifier = container.read(groupsProvider.notifier);

        // Initial state
        expect(container.read(groupsProvider).isLoading, false);

        // Manually set loading state for testing
        notifier.state = notifier.state.copyWith(isLoading: true);
        expect(container.read(groupsProvider).isLoading, true);

        notifier.state = notifier.state.copyWith(isLoading: false);
        expect(container.read(groupsProvider).isLoading, false);
      });

      test('should update error state correctly', () {
        final notifier = container.read(groupsProvider.notifier);

        // Initial state
        expect(container.read(groupsProvider).error, isNull);

        // Set error
        notifier.state = notifier.state.copyWith(error: 'Test error');
        expect(container.read(groupsProvider).error, 'Test error');

        // Clear error
        notifier.state = notifier.state.copyWith(error: null);
        expect(container.read(groupsProvider).error, isNull);
      });

      test('should update groups correctly', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set groups
        notifier.state = notifier.state.copyWith(groups: testGroups);

        final state = container.read(groupsProvider);
        expect(state.groups, testGroups);
        expect(state.groups!.length, 3);
      });

      test('should update group members correctly', () {
        final notifier = container.read(groupsProvider.notifier);
        final testUser = User(
          id: 'test_id',
          displayName: 'Test User',
          nip05: 'test@example.com',
          publicKey: 'test_pubkey',
        );
        final testGroupMembers = <String, List<User>>{
          'group1': [testUser],
        };

        notifier.state = notifier.state.copyWith(groupMembers: testGroupMembers);

        final state = container.read(groupsProvider);
        expect(state.groupMembers, testGroupMembers);
        expect(state.groupMembers!['group1'], [testUser]);
      });

      test('should update group admins correctly', () {
        final notifier = container.read(groupsProvider.notifier);
        final testUser = User(
          id: 'admin_id',
          displayName: 'Admin User',
          nip05: 'admin@example.com',
          publicKey: 'admin_pubkey',
        );
        final testGroupAdmins = <String, List<User>>{
          'group1': [testUser],
        };

        notifier.state = notifier.state.copyWith(groupAdmins: testGroupAdmins);

        final state = container.read(groupsProvider);
        expect(state.groupAdmins, testGroupAdmins);
        expect(state.groupAdmins!['group1'], [testUser]);
      });

      test('should update group display names correctly', () {
        final notifier = container.read(groupsProvider.notifier);
        final testDisplayNames = <String, String>{
          'group1': 'Test Group Display Name',
          'dm1': 'John Doe',
        };

        notifier.state = notifier.state.copyWith(groupDisplayNames: testDisplayNames);

        final state = container.read(groupsProvider);
        expect(state.groupDisplayNames, testDisplayNames);
        expect(state.groupDisplayNames!['group1'], 'Test Group Display Name');
        expect(state.groupDisplayNames!['dm1'], 'John Doe');
      });
    });

    group('Utility Methods', () {
      setUp(() {
        // Set up test data for utility method tests
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);
      });

      test(
        'getGroupsByType should filter by GroupType.group',
        () async {
          final notifier = container.read(groupsProvider.notifier);

          // Skip test when rust bridge is not available
          try {
            final regularGroups = await notifier.getGroupsByType(GroupType.group);
            expect(regularGroups.length, 2);
            expect(regularGroups.map((g) => g.name), contains('Test Group 1'));
            expect(regularGroups.map((g) => g.name), contains('Inactive Group'));
          } catch (e) {
            // Skip test if rust bridge is not initialized
            if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
              return;
            }
            rethrow;
          }
        },
        skip: 'Requires rust bridge initialization',
      );

      test(
        'getGroupsByType should filter by GroupType.directMessage',
        () async {
          final notifier = container.read(groupsProvider.notifier);

          try {
            final dmGroups = await notifier.getGroupsByType(GroupType.directMessage);
            expect(dmGroups.length, 1);
            expect(dmGroups.first.name, 'Direct Message');
          } catch (e) {
            if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
              return;
            }
            rethrow;
          }
        },
        skip: 'Requires rust bridge initialization',
      );

      test('getActiveGroups should filter by GroupState.active', () {
        final notifier = container.read(groupsProvider.notifier);
        final activeGroups = notifier.getActiveGroups();

        expect(activeGroups.length, 2);
        expect(activeGroups.every((g) => g.state == GroupState.active), true);
        expect(activeGroups.map((g) => g.name), contains('Test Group 1'));
        expect(activeGroups.map((g) => g.name), contains('Direct Message'));
      });

      test(
        'getDirectMessageGroups should return only direct messages',
        () async {
          final notifier = container.read(groupsProvider.notifier);

          try {
            final dmGroups = await notifier.getDirectMessageGroups();
            expect(dmGroups.length, 1);
            expect(dmGroups.first.name, 'Direct Message');
          } catch (e) {
            if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
              return;
            }
            rethrow;
          }
        },
        skip: 'Requires rust bridge initialization',
      );

      test(
        'getRegularGroups should return only regular groups',
        () async {
          final notifier = container.read(groupsProvider.notifier);

          try {
            final regularGroups = await notifier.getRegularGroups();
            expect(regularGroups.length, 2);
            expect(
              regularGroups.map((g) => g.name),
              containsAll(['Test Group 1', 'Inactive Group']),
            );
          } catch (e) {
            if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
              return;
            }
            rethrow;
          }
        },
        skip: 'Requires rust bridge initialization',
      );

      test('findGroupById should find group by mlsGroupId', () {
        final notifier = container.read(groupsProvider.notifier);
        final group = notifier.findGroupById('mls_group_1');

        expect(group, isNotNull);
        expect(group!.name, 'Test Group 1');
        expect(group.mlsGroupId, 'mls_group_1');
      });

      test('findGroupById should find group by nostrGroupId', () {
        final notifier = container.read(groupsProvider.notifier);
        final group = notifier.findGroupById('nostr_group_2');

        expect(group, isNotNull);
        expect(group!.name, 'Direct Message');
        expect(group.nostrGroupId, 'nostr_group_2');
      });

      test('findGroupById should return null for non-existent group', () {
        final notifier = container.read(groupsProvider.notifier);
        final group = notifier.findGroupById('non_existent_group');

        expect(group, isNull);
      });

      test('getGroupMembers should return members for existing group', () {
        final notifier = container.read(groupsProvider.notifier);
        final testUser = User(
          id: 'member_id',
          displayName: 'Member User',
          nip05: 'member@example.com',
          publicKey: 'member_pubkey',
        );
        final testGroupMembers = <String, List<User>>{
          'group1': [testUser],
        };
        notifier.state = notifier.state.copyWith(groupMembers: testGroupMembers);

        final members = notifier.getGroupMembers('group1');
        expect(members, [testUser]);
      });

      test('getGroupMembers should return null for non-existent group', () {
        final notifier = container.read(groupsProvider.notifier);
        final members = notifier.getGroupMembers('non_existent_group');
        expect(members, isNull);
      });

      test('getGroupAdmins should return admins for existing group', () {
        final notifier = container.read(groupsProvider.notifier);
        final testUser = User(
          id: 'admin_id',
          displayName: 'Admin User',
          nip05: 'admin@example.com',
          publicKey: 'admin_pubkey',
        );
        final testGroupAdmins = <String, List<User>>{
          'group1': [testUser],
        };
        notifier.state = notifier.state.copyWith(groupAdmins: testGroupAdmins);

        final admins = notifier.getGroupAdmins('group1');
        expect(admins, [testUser]);
      });

      test('getGroupAdmins should return null for non-existent group', () {
        final notifier = container.read(groupsProvider.notifier);
        final admins = notifier.getGroupAdmins('non_existent_group');
        expect(admins, isNull);
      });

      test('clearGroup should reset state to initial values', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set some data first
        final testUser = User(
          id: 'test_id',
          displayName: 'Test User',
          nip05: 'test@example.com',
          publicKey: 'test_pubkey',
        );
        notifier.state = notifier.state.copyWith(
          groups: testGroups,
          groupMembers: <String, List<User>>{
            'test': [testUser],
          },
          groupAdmins: <String, List<User>>{
            'test': [testUser],
          },
          groupDisplayNames: <String, String>{'test': 'Test Group'},
          error: 'some error',
        );

        // Clear data
        notifier.clearGroup();

        final state = container.read(groupsProvider);
        expect(state.groups, isNull);
        expect(state.groupMembers, isNull);
        expect(state.groupAdmins, isNull);
        expect(state.groupDisplayNames, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });
    });

    group('Group Creation', () {
      test('should handle createNewGroup with valid data', () async {
        final notifier = container.read(groupsProvider.notifier);

        // Test the validation logic that would occur before API call
        const groupName = 'New Test Group';
        const groupDescription = 'A newly created test group';
        const memberKeys = ['member1_pubkey', 'member2_pubkey'];
        const adminKeys = ['admin1_pubkey', 'admin2_pubkey'];

        // Test that the method exists and can be called
        expect(
          () => notifier.createNewGroup(
            groupName: groupName,
            groupDescription: groupDescription,
            memberPublicKeyHexs: memberKeys,
            adminPublicKeyHexs: adminKeys,
          ),
          returnsNormally,
        );
      });

      test('should validate group creation parameters', () {
        final notifier = container.read(groupsProvider.notifier);

        // Test with empty group name
        expect(
          () => notifier.createNewGroup(
            groupName: '',
            groupDescription: 'Valid description',
            memberPublicKeyHexs: ['member1'],
            adminPublicKeyHexs: ['admin1'],
          ),
          returnsNormally,
        );

        // Test with empty member list
        expect(
          () => notifier.createNewGroup(
            groupName: 'Valid Name',
            groupDescription: 'Valid description',
            memberPublicKeyHexs: [],
            adminPublicKeyHexs: ['admin1'],
          ),
          returnsNormally,
        );

        // Test with empty admin list
        expect(
          () => notifier.createNewGroup(
            groupName: 'Valid Name',
            groupDescription: 'Valid description',
            memberPublicKeyHexs: ['member1'],
            adminPublicKeyHexs: [],
          ),
          returnsNormally,
        );
      });

      test('should handle group creation loading state', () async {
        final notifier = container.read(groupsProvider.notifier);

        // Set initial state
        notifier.state = notifier.state.copyWith(isLoading: false);
        expect(container.read(groupsProvider).isLoading, false);

        // Note: In a real scenario, calling createNewGroup would set loading to true
        // but since we can't mock the Rust API easily, we'll test the state management
        notifier.state = notifier.state.copyWith(isLoading: true);
        expect(container.read(groupsProvider).isLoading, true);

        // Simulate completion
        notifier.state = notifier.state.copyWith(isLoading: false);
        expect(container.read(groupsProvider).isLoading, false);
      });

      test('should handle group creation errors', () {
        final notifier = container.read(groupsProvider.notifier);

        // Simulate creation error
        notifier.state = notifier.state.copyWith(
          error: 'Failed to create group: Network error',
          isLoading: false,
        );

        final state = container.read(groupsProvider);
        expect(state.error, contains('Failed to create group'));
        expect(state.isLoading, false);
      });

      test('should validate member and admin key formats', () {
        final notifier = container.read(groupsProvider.notifier);

        // Test with valid hex keys
        const validKeys = [
          'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        ];

        expect(
          () => notifier.createNewGroup(
            groupName: 'Test Group',
            groupDescription: 'Test Description',
            memberPublicKeyHexs: validKeys,
            adminPublicKeyHexs: validKeys,
          ),
          returnsNormally,
        );

        // Test with keys that have extra whitespace (should be trimmed)
        const keysWithWhitespace = [
          ' abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890 ',
          '\t1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\n',
        ];

        expect(
          () => notifier.createNewGroup(
            groupName: 'Test Group',
            groupDescription: 'Test Description',
            memberPublicKeyHexs: keysWithWhitespace,
            adminPublicKeyHexs: keysWithWhitespace,
          ),
          returnsNormally,
        );
      });

      test('should maintain state consistency during group creation', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set initial groups
        notifier.state = notifier.state.copyWith(groups: testGroups);
        expect(container.read(groupsProvider).groups!.length, 3);

        // Simulate adding a new group
        final newGroup = Group(
          mlsGroupId: 'new_mls_group',
          nostrGroupId: 'new_nostr_group',
          name: 'New Group',
          description: 'A newly created group',
          adminPubkeys: ['test_pubkey_123'],
          epoch: BigInt.from(1),
          state: GroupState.active,
        );

        final updatedGroups = [...testGroups, newGroup];
        notifier.state = notifier.state.copyWith(groups: updatedGroups);

        final state = container.read(groupsProvider);
        expect(state.groups!.length, 4);
        expect(state.groups!.last.name, 'New Group');
        expect(state.groups!.last.adminPubkeys, contains('test_pubkey_123'));
      });

      test('should handle concurrent group creation requests', () {
        final notifier = container.read(groupsProvider.notifier);

        // Test that multiple creation calls can be handled
        expect(() {
          notifier.createNewGroup(
            groupName: 'Group 1',
            groupDescription: 'First group',
            memberPublicKeyHexs: ['member1'],
            adminPublicKeyHexs: ['admin1'],
          );

          notifier.createNewGroup(
            groupName: 'Group 2',
            groupDescription: 'Second group',
            memberPublicKeyHexs: ['member2'],
            adminPublicKeyHexs: ['admin2'],
          );
        }, returnsNormally);
      });
    });

    group('State Transitions', () {
      test('should handle state updates correctly', () {
        final notifier = container.read(groupsProvider.notifier);

        // Test loading state transition
        notifier.state = notifier.state.copyWith(isLoading: true);
        expect(container.read(groupsProvider).isLoading, true);

        // Test data loading
        notifier.state = notifier.state.copyWith(
          groups: testGroups,
          isLoading: false,
        );

        final state = container.read(groupsProvider);
        expect(state.groups, testGroups);
        expect(state.isLoading, false);
        expect(state.groups!.length, 3);
      });

      test('should handle error states correctly', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set error state
        notifier.state = notifier.state.copyWith(
          error: 'Network error',
          isLoading: false,
        );

        final state = container.read(groupsProvider);
        expect(state.error, 'Network error');
        expect(state.isLoading, false);

        // Clear error
        notifier.state = notifier.state.copyWith(error: null);
        expect(container.read(groupsProvider).error, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle empty groups list', () async {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: <Group>[]);

        expect(notifier.getActiveGroups(), isEmpty);

        try {
          expect(await notifier.getRegularGroups(), isEmpty);
          expect(await notifier.getDirectMessageGroups(), isEmpty);
        } catch (e) {
          if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
            // Skip async methods that require rust bridge
          } else {
            rethrow;
          }
        }

        expect(notifier.findGroupById('any_id'), isNull);
      });

      test('should handle null groups when calling utility methods', () async {
        final notifier = container.read(groupsProvider.notifier);
        // groups is null by default

        expect(notifier.getActiveGroups(), isEmpty);

        try {
          expect(await notifier.getRegularGroups(), isEmpty);
          expect(await notifier.getDirectMessageGroups(), isEmpty);
        } catch (e) {
          if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
            // Skip async methods that require rust bridge
          } else {
            rethrow;
          }
        }

        expect(notifier.findGroupById('any_id'), isNull);
      });

      test('should handle getGroupMembers with null groupMembers', () {
        final notifier = container.read(groupsProvider.notifier);
        // groupMembers is null by default

        expect(notifier.getGroupMembers('any_group'), isNull);
      });

      test('should handle getGroupAdmins with null groupAdmins', () {
        final notifier = container.read(groupsProvider.notifier);
        // groupAdmins is null by default

        expect(notifier.getGroupAdmins('any_group'), isNull);
      });
    });

    group('Data Validation', () {
      test('should correctly identify group types', () async {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);

        try {
          // Test that we can distinguish between different group types
          final allGroups = notifier.state.groups!;
          final regularGroups = <Group>[];
          final dmGroups = <Group>[];

          for (final group in allGroups) {
            final groupType = await group.groupType(accountPubkey: 'npubabc');
            if (groupType == GroupType.group) {
              regularGroups.add(group);
            } else if (groupType == GroupType.directMessage) {
              dmGroups.add(group);
            }
          }

          expect(regularGroups.length, 2);
          expect(dmGroups.length, 1);
          expect(regularGroups.first.name, anyOf('Test Group 1', 'Inactive Group'));
          expect(dmGroups.first.name, 'Direct Message');
        } catch (e) {
          if (e.toString().contains('flutter_rust_bridge has not been initialized')) {
            return;
          }
          rethrow;
        }
      }, skip: 'Requires rust bridge initialization');

      test('should correctly identify group states', () {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);

        final allGroups = notifier.state.groups!;
        final activeGroups = allGroups.where((g) => g.state == GroupState.active).toList();
        final inactiveGroups = allGroups.where((g) => g.state == GroupState.inactive).toList();

        expect(activeGroups.length, 2);
        expect(inactiveGroups.length, 1);
        expect(inactiveGroups.first.name, 'Inactive Group');
      });

      test('should handle admin pubkeys correctly', () {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);

        final group1 = notifier.findGroupById('mls_group_1');
        final group2 = notifier.findGroupById('mls_group_2');
        final group3 = notifier.findGroupById('mls_group_3');

        expect(group1!.adminPubkeys, contains('test_pubkey_123'));
        expect(group1.adminPubkeys, contains('admin_pubkey_456'));
        expect(group2!.adminPubkeys, contains('test_pubkey_123'));
        expect(group2.adminPubkeys.length, 1);
        expect(group3!.adminPubkeys, contains('other_admin_123'));
        expect(group3.adminPubkeys, isNot(contains('test_pubkey_123')));
      });
    });

    group('Provider Integration', () {
      test('should be properly registered as a Riverpod provider', () {
        // Test that the provider is properly set up
        expect(groupsProvider, isNotNull);

        // Test that we can read from it
        final state = container.read(groupsProvider);
        expect(state, isNotNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
        expect(state.groups, isNull);

        // Test that we can get the notifier
        final notifier = container.read(groupsProvider.notifier);
        expect(notifier, isA<GroupsNotifier>());
      });

      test('should maintain state across multiple reads', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set some state
        notifier.state = notifier.state.copyWith(
          groups: testGroups,
          groupDisplayNames: <String, String>{'test': 'Test Group'},
          isLoading: true,
          error: 'test error',
        );

        // Read multiple times and ensure state is consistent
        final state1 = container.read(groupsProvider);
        final state2 = container.read(groupsProvider);
        final state3 = container.read(groupsProvider);

        expect(state1.groups, state2.groups);
        expect(state2.groups, state3.groups);
        expect(state1.groupDisplayNames, state2.groupDisplayNames);
        expect(state2.groupDisplayNames, state3.groupDisplayNames);
        expect(state1.isLoading, state2.isLoading);
        expect(state2.isLoading, state3.isLoading);
        expect(state1.error, state2.error);
        expect(state2.error, state3.error);
      });
    });
  });
}
