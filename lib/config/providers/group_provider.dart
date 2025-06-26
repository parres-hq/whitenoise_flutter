// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/src/rust/api.dart';

class GroupsNotifier extends Notifier<GroupsState> {
  final _logger = Logger('GroupsNotifier');

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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groups = await fetchGroups(pubkey: publicKey);

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e, st) {
      _logger.severe('GroupsProvider.loadGroups', e, st);
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<GroupData?> createNewGroup({
    required String groupName,
    required String groupDescription,
    required List<String> memberPublicKeyHexs,
    required List<String> adminPublicKeyHexs,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return null;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return null;
      }

      final creatorPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      final resolvedMembersPublicKeys = await Future.wait(
        memberPublicKeyHexs.toSet().map(
          (hexKey) async => await publicKeyFromString(publicKeyString: hexKey.trim()),
        ),
      );
      _logger.info('GroupsProvider: Members pubkeys loaded - ${resolvedMembersPublicKeys.length}');

      final resolvedAdminPublicKeys = await Future.wait(
        adminPublicKeyHexs.toSet().map(
          (hexKey) async => await publicKeyFromString(publicKeyString: hexKey.trim()),
        ),
      );

      final combinedAdminKeys = {creatorPubkey, ...resolvedAdminPublicKeys}.toList();
      _logger.info('GroupsProvider: Admin pubkeys loaded - ${combinedAdminKeys.length}');

      final newGroup = await createGroup(
        creatorPubkey: creatorPubkey,
        memberPubkeys: resolvedMembersPublicKeys,
        adminPubkeys: combinedAdminKeys,
        groupName: groupName,
        groupDescription: groupDescription,
      );

      _logger.info('GroupsProvider: Group created successfully - ${newGroup.name}');

      await loadGroups();
      return newGroup;
    } catch (e, st) {
      _logger.severe('GroupsProvider.createNewGroup', e, st);
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  Future<void> loadGroupMembers(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);
      final members = await fetchGroupMembers(pubkey: publicKey, groupId: groupIdObj);

      _logger.info('GroupsProvider: Loaded ${members.length} members for group $groupId');

      final updatedGroupMembers = Map<String, List<PublicKey>>.from(state.groupMembers ?? {});
      updatedGroupMembers[groupId] = members;

      state = state.copyWith(groupMembers: updatedGroupMembers);
    } catch (e, st) {
      _logger.severe('GroupsProvider.loadGroupMembers', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadGroupAdmins(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groupIdObj = await groupIdFromString(hexString: groupId);
      final admins = await fetchGroupAdmins(pubkey: publicKey, groupId: groupIdObj);

      _logger.info('GroupsProvider: Loaded ${admins.length} admins for group $groupId');

      final updatedGroupAdmins = Map<String, List<PublicKey>>.from(state.groupAdmins ?? {});
      updatedGroupAdmins[groupId] = admins;

      state = state.copyWith(groupAdmins: updatedGroupAdmins);
    } catch (e, st) {
      _logger.severe('GroupsProvider.loadGroupAdmins', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadGroupDetails(String groupId) async {
    // Load both members and admins for a group
    await Future.wait([
      loadGroupMembers(groupId),
      loadGroupAdmins(groupId),
    ]);
  }

  List<GroupData> getGroupsByType(GroupType type) {
    final groups = state.groups;
    if (groups == null) return [];
    return groups.where((group) => group.groupType == type).toList();
  }

  List<GroupData> getActiveGroups() {
    final groups = state.groups;
    if (groups == null) return [];
    return groups.where((group) => group.state == GroupState.active).toList();
  }

  List<GroupData> getDirectMessageGroups() {
    return getGroupsByType(GroupType.directMessage);
  }

  // Get regular groups (not direct messages)
  List<GroupData> getRegularGroups() {
    return getGroupsByType(GroupType.group);
  }

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

  List<PublicKey>? getGroupMembers(String groupId) {
    return state.groupMembers?[groupId];
  }

  List<PublicKey>? getGroupAdmins(String groupId) {
    return state.groupAdmins?[groupId];
  }

  Future<bool> isCurrentUserAdmin(String groupId) async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) return false;

      final group = findGroupById(groupId);
      if (group == null) return false;

      return group.adminPubkeys.contains(activeAccountData.pubkey);
    } catch (e) {
      _logger.info('GroupsProvider: Error checking admin status: $e');
      return false;
    }
  }

  void clearGroupData() {
    state = const GroupsState();
  }

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

final groupsProvider = NotifierProvider<GroupsNotifier, GroupsState>(
  GroupsNotifier.new,
);
