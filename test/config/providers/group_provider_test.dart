import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

void main() {
  group('GroupsProvider Tests', () {
    late ProviderContainer container;

    // Test data
    final testGroupData1 = GroupData(
      mlsGroupId: 'mls_group_1',
      nostrGroupId: 'nostr_group_1',
      name: 'Test Group 1',
      description: 'A test group',
      adminPubkeys: ['test_pubkey_123', 'admin_pubkey_456'],
      lastMessageId: 'message_1',
      lastMessageAt: BigInt.from(1234567890),
      groupType: GroupType.group,
      epoch: BigInt.from(1),
      state: GroupState.active,
    );

    final testGroupData2 = GroupData(
      mlsGroupId: 'mls_group_2',
      nostrGroupId: 'nostr_group_2',
      name: 'Direct Message',
      description: 'A direct message',
      adminPubkeys: ['test_pubkey_123'],
      groupType: GroupType.directMessage,
      epoch: BigInt.from(1),
      state: GroupState.active,
    );

    final testGroupData3 = GroupData(
      mlsGroupId: 'mls_group_3',
      nostrGroupId: 'nostr_group_3',
      name: 'Inactive Group',
      description: 'An inactive group',
      adminPubkeys: ['other_admin_123'],
      groupType: GroupType.group,
      epoch: BigInt.from(1),
      state: GroupState.inactive,
    );

    final testGroups = [testGroupData1, testGroupData2, testGroupData3];

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
        final testGroupMembers = <String, List<PublicKey>>{'group1': []};

        notifier.state = notifier.state.copyWith(groupMembers: testGroupMembers);

        final state = container.read(groupsProvider);
        expect(state.groupMembers, testGroupMembers);
        expect(state.groupMembers!['group1'], []);
      });

      test('should update group admins correctly', () {
        final notifier = container.read(groupsProvider.notifier);
        final testGroupAdmins = <String, List<PublicKey>>{'group1': []};

        notifier.state = notifier.state.copyWith(groupAdmins: testGroupAdmins);

        final state = container.read(groupsProvider);
        expect(state.groupAdmins, testGroupAdmins);
        expect(state.groupAdmins!['group1'], []);
      });
    });

    group('Utility Methods', () {
      setUp(() {
        // Set up test data for utility method tests
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);
      });

      test('getGroupsByType should filter by GroupType.group', () {
        final notifier = container.read(groupsProvider.notifier);
        final regularGroups = notifier.getGroupsByType(GroupType.group);

        expect(regularGroups.length, 2);
        expect(regularGroups.every((g) => g.groupType == GroupType.group), true);
        expect(regularGroups.map((g) => g.name), contains('Test Group 1'));
        expect(regularGroups.map((g) => g.name), contains('Inactive Group'));
      });

      test('getGroupsByType should filter by GroupType.directMessage', () {
        final notifier = container.read(groupsProvider.notifier);
        final dmGroups = notifier.getGroupsByType(GroupType.directMessage);

        expect(dmGroups.length, 1);
        expect(dmGroups.first.groupType, GroupType.directMessage);
        expect(dmGroups.first.name, 'Direct Message');
      });

      test('getActiveGroups should filter by GroupState.active', () {
        final notifier = container.read(groupsProvider.notifier);
        final activeGroups = notifier.getActiveGroups();

        expect(activeGroups.length, 2);
        expect(activeGroups.every((g) => g.state == GroupState.active), true);
        expect(activeGroups.map((g) => g.name), contains('Test Group 1'));
        expect(activeGroups.map((g) => g.name), contains('Direct Message'));
      });

      test('getDirectMessageGroups should return only direct messages', () {
        final notifier = container.read(groupsProvider.notifier);
        final dmGroups = notifier.getDirectMessageGroups();

        expect(dmGroups.length, 1);
        expect(dmGroups.first.groupType, GroupType.directMessage);
        expect(dmGroups.first.name, 'Direct Message');
      });

      test('getRegularGroups should return only regular groups', () {
        final notifier = container.read(groupsProvider.notifier);
        final regularGroups = notifier.getRegularGroups();

        expect(regularGroups.length, 2);
        expect(regularGroups.every((g) => g.groupType == GroupType.group), true);
        expect(regularGroups.map((g) => g.name), containsAll(['Test Group 1', 'Inactive Group']));
      });

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
        final testGroupMembers = <String, List<PublicKey>>{'group1': []};
        notifier.state = notifier.state.copyWith(groupMembers: testGroupMembers);

        final members = notifier.getGroupMembers('group1');
        expect(members, []);
      });

      test('getGroupMembers should return null for non-existent group', () {
        final notifier = container.read(groupsProvider.notifier);
        final members = notifier.getGroupMembers('non_existent_group');
        expect(members, isNull);
      });

      test('getGroupAdmins should return admins for existing group', () {
        final notifier = container.read(groupsProvider.notifier);
        final testGroupAdmins = <String, List<PublicKey>>{'group1': []};
        notifier.state = notifier.state.copyWith(groupAdmins: testGroupAdmins);

        final admins = notifier.getGroupAdmins('group1');
        expect(admins, []);
      });

      test('getGroupAdmins should return null for non-existent group', () {
        final notifier = container.read(groupsProvider.notifier);
        final admins = notifier.getGroupAdmins('non_existent_group');
        expect(admins, isNull);
      });

      test('clearGroupData should reset state to initial values', () {
        final notifier = container.read(groupsProvider.notifier);

        // Set some data first
        notifier.state = notifier.state.copyWith(
          groups: testGroups,
          groupMembers: <String, List<PublicKey>>{'test': []},
          groupAdmins: <String, List<PublicKey>>{'test': []},
          error: 'some error',
        );

        // Clear data
        notifier.clearGroupData();

        final state = container.read(groupsProvider);
        expect(state.groups, isNull);
        expect(state.groupMembers, isNull);
        expect(state.groupAdmins, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);
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
      test('should handle empty groups list', () {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: <GroupData>[]);

        expect(notifier.getActiveGroups(), isEmpty);
        expect(notifier.getRegularGroups(), isEmpty);
        expect(notifier.getDirectMessageGroups(), isEmpty);
        expect(notifier.findGroupById('any_id'), isNull);
      });

      test('should handle null groups when calling utility methods', () {
        final notifier = container.read(groupsProvider.notifier);
        // groups is null by default

        expect(notifier.getActiveGroups(), isEmpty);
        expect(notifier.getRegularGroups(), isEmpty);
        expect(notifier.getDirectMessageGroups(), isEmpty);
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
      test('should correctly identify group types', () {
        final notifier = container.read(groupsProvider.notifier);
        notifier.state = notifier.state.copyWith(groups: testGroups);

        // Test that we can distinguish between different group types
        final allGroups = notifier.state.groups!;
        final regularGroups = allGroups.where((g) => g.groupType == GroupType.group).toList();
        final dmGroups = allGroups.where((g) => g.groupType == GroupType.directMessage).toList();

        expect(regularGroups.length, 2);
        expect(dmGroups.length, 1);
        expect(regularGroups.first.name, anyOf('Test Group 1', 'Inactive Group'));
        expect(dmGroups.first.name, 'Direct Message');
      });

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
          isLoading: true,
          error: 'test error',
        );

        // Read multiple times and ensure state is consistent
        final state1 = container.read(groupsProvider);
        final state2 = container.read(groupsProvider);
        final state3 = container.read(groupsProvider);

        expect(state1.groups, state2.groups);
        expect(state2.groups, state3.groups);
        expect(state1.isLoading, state2.isLoading);
        expect(state2.isLoading, state3.isLoading);
        expect(state1.error, state2.error);
        expect(state2.error, state3.error);
      });
    });
  });
}
