// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/src/rust/api.dart';

class GroupsNotifier extends Notifier<GroupsState> {
  @override
  GroupsState build() => const GroupsState();

  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Get active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groups = await fetchGroups(pubkey: publicKey);

      debugPrint('GroupsProvider: Loaded ${groups.length} groups');
      for (final group in groups) {
        debugPrint(
          'GroupsProvider: Group - name: ${group.name}, type: ${group.groupType}, state: ${group.state}',
        );
      }

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e, st) {
      debugPrintStack(label: 'GroupsProvider.loadGroups', stackTrace: st);
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<GroupData?> createNewGroup({
    required String groupName,
    required String groupDescription,
    required List<String> memberPublicKeys, // hex strings
    required List<String> adminPublicKeys, // hex strings
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return null;
    }

    try {
      // Get active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return null;
      }

      final creatorPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      final memberPubkeys = <PublicKey>[];
      for (final hexKey in memberPublicKeys) {
        memberPubkeys.add(await publicKeyFromString(publicKeyString: hexKey.trim()));
      }

      final adminPubkeys = <PublicKey>[];
      for (final hexKey in adminPublicKeys) {
        adminPubkeys.add(await publicKeyFromString(publicKeyString: hexKey.trim()));
      }

      debugPrint(
        'GroupsProvider: Creating group "$groupName" with ${memberPubkeys.length} members and ${adminPubkeys.length} admins',
      );

      final newGroup = await createGroup(
        creatorPubkey: creatorPubkey,
        memberPubkeys: memberPubkeys,
        adminPubkeys: adminPubkeys,
        groupName: groupName,
        groupDescription: groupDescription,
      );

      debugPrint('GroupsProvider: Group created successfully - ${newGroup.name}');

      // Refresh the groups list
      await loadGroups();

      return newGroup;
    } catch (e, st) {
      debugPrintStack(label: 'GroupsProvider.createNewGroup', stackTrace: st);
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  // Load members for a specific group
  Future<void> loadGroupMembers(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      // Get active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);
      final members = await fetchGroupMembers(pubkey: publicKey, groupId: groupIdObj);

      debugPrint('GroupsProvider: Loaded ${members.length} members for group $groupId');

      final updatedGroupMembers = Map<String, List<PublicKey>>.from(state.groupMembers ?? {});
      updatedGroupMembers[groupId] = members;

      state = state.copyWith(groupMembers: updatedGroupMembers);
    } catch (e, st) {
      debugPrintStack(label: 'GroupsProvider.loadGroupMembers', stackTrace: st);
      state = state.copyWith(error: e.toString());
    }
  }

  // Load admins for a specific group
  Future<void> loadGroupAdmins(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      // Get active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);
      final admins = await fetchGroupAdmins(pubkey: publicKey, groupId: groupIdObj);

      debugPrint('GroupsProvider: Loaded ${admins.length} admins for group $groupId');

      final updatedGroupAdmins = Map<String, List<PublicKey>>.from(state.groupAdmins ?? {});
      updatedGroupAdmins[groupId] = admins;

      state = state.copyWith(groupAdmins: updatedGroupAdmins);
    } catch (e, st) {
      debugPrintStack(label: 'GroupsProvider.loadGroupAdmins', stackTrace: st);
      state = state.copyWith(error: e.toString());
    }
  }

  // Load both members and admins for a group
  Future<void> loadGroupDetails(String groupId) async {
    await Future.wait([
      loadGroupMembers(groupId),
      loadGroupAdmins(groupId),
    ]);
  }

  // Get groups by type
  List<GroupData> getGroupsByType(GroupType type) {
    final groups = state.groups;
    if (groups == null) return [];
    return groups.where((group) => group.groupType == type).toList();
  }

  // Get active groups only
  List<GroupData> getActiveGroups() {
    final groups = state.groups;
    if (groups == null) return [];
    return groups.where((group) => group.state == GroupState.active).toList();
  }

  // Get direct message groups
  List<GroupData> getDirectMessageGroups() {
    return getGroupsByType(GroupType.directMessage);
  }

  // Get regular groups (not direct messages)
  List<GroupData> getRegularGroups() {
    return getGroupsByType(GroupType.group);
  }

  // Find a group by ID
  GroupData? findGroupById(String groupId) {
    final groups = state.groups;
    if (groups == null) return null;

    try {
      return groups.firstWhere(
        (group) => group.mlsGroupId == groupId || group.nostrGroupId == groupId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get members for a specific group
  List<PublicKey>? getGroupMembers(String groupId) {
    return state.groupMembers?[groupId];
  }

  // Get admins for a specific group
  List<PublicKey>? getGroupAdmins(String groupId) {
    return state.groupAdmins?[groupId];
  }

  // Check if current user is admin of a group
  Future<bool> isCurrentUserAdmin(String groupId) async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) return false;

      final group = findGroupById(groupId);
      if (group == null) return false;

      // GroupData.adminPubkeys is already a List<String>, so we can compare directly
      return group.adminPubkeys.contains(activeAccountData.pubkey);
    } catch (e) {
      debugPrint('GroupsProvider: Error checking admin status: $e');
      return false;
    }
  }

  // Clear all group data
  void clearGroupData() {
    state = const GroupsState();
  }

  // Refresh all group data
  Future<void> refreshAllData() async {
    await loadGroups();

    // Load details for all groups
    final groups = state.groups;
    if (groups != null) {
      for (final group in groups) {
        await loadGroupDetails(group.mlsGroupId);
      }
    }
  }
}

// Riverpod provider
final groupsProvider = NotifierProvider<GroupsNotifier, GroupsState>(
  GroupsNotifier.new,
);
