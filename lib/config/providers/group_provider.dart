// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/domain/models/user_model.dart';
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

      // First set the groups
      state = state.copyWith(groups: groups);

      // Load members for all groups to enable proper display name calculation
      await _loadMembersForAllGroups(groups);

      // Now calculate display names with member data available
      await _calculateDisplayNames(groups, activeAccountData.pubkey);

      state = state.copyWith(isLoading: false);
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

      final creatorPubkeyForAdmin = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final combinedAdminKeys = {creatorPubkeyForAdmin, ...resolvedAdminPublicKeys}.toList();
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
      final memberPubkeys = await fetchGroupMembers(pubkey: publicKey, groupId: groupIdObj);

      _logger.info('GroupsProvider: Loaded ${memberPubkeys.length} members for group $groupId');

      // Fetch metadata for each member and create User objects
      final List<User> members = [];
      for (final memberPubkey in memberPubkeys) {
        try {
          final pubkeyString = await exportAccountNpub(pubkey: memberPubkey);

          try {
            final metadata = await fetchMetadata(pubkey: memberPubkey);
            if (metadata != null) {
              final user = User.fromMetadata(metadata, pubkeyString);
              members.add(user);
            } else {
              // Create fallback user if metadata is null
              final fallbackUser = User(
                id: pubkeyString,
                name: 'Unknown User',
                nip05: '',
                publicKey: pubkeyString,
              );
              members.add(fallbackUser);
            }
          } catch (metadataError) {
            _logger.warning('Failed to fetch metadata for member: $metadataError');
            // Create a fallback user with minimal info
            final fallbackUser = User(
              id: pubkeyString,
              name: 'Unknown User',
              nip05: '',
              publicKey: pubkeyString,
            );
            members.add(fallbackUser);
          }
        } catch (e) {
          _logger.severe('Failed to process member pubkey: $e');
          // Skip this member if we can't even get the pubkey string
        }
      }

      final updatedGroupMembers = Map<String, List<User>>.from(state.groupMembers ?? {});
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
      final adminPubkeys = await fetchGroupAdmins(pubkey: publicKey, groupId: groupIdObj);

      _logger.info('GroupsProvider: Loaded ${adminPubkeys.length} admins for group $groupId');

      // Fetch metadata for each admin and create User objects
      final List<User> admins = [];
      for (final adminPubkey in adminPubkeys) {
        try {
          // Get pubkey string first to avoid multiple uses of the same PublicKey object
          final pubkeyString = await exportAccountNpub(pubkey: adminPubkey);

          try {
            final metadata = await fetchMetadata(pubkey: adminPubkey);
            if (metadata != null) {
              final user = User.fromMetadata(metadata, pubkeyString);
              admins.add(user);
            } else {
              // Create fallback user if metadata is null
              final fallbackUser = User(
                id: pubkeyString,
                name: 'Unknown User',
                nip05: '',
                publicKey: pubkeyString,
              );
              admins.add(fallbackUser);
            }
          } catch (metadataError) {
            _logger.warning('Failed to fetch metadata for admin: $metadataError');
            // Create a fallback user with minimal info
            final fallbackUser = User(
              id: pubkeyString,
              name: 'Unknown User',
              nip05: '',
              publicKey: pubkeyString,
            );
            admins.add(fallbackUser);
          }
        } catch (e) {
          _logger.severe('Failed to process admin pubkey: $e');
          // Skip this admin if we can't even get the pubkey string
        }
      }

      final updatedGroupAdmins = Map<String, List<User>>.from(state.groupAdmins ?? {});
      updatedGroupAdmins[groupId] = admins;

      state = state.copyWith(groupAdmins: updatedGroupAdmins);
    } catch (e, st) {
      _logger.severe('GroupsProvider.loadGroupAdmins', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  // Load the group creator information
  Future<void> loadGroupCreator() async {
    if (!_isAuthAvailable()) {
      return;
    }

    // checks the group members
  }

  Future<void> loadGroupDetails(String groupId) async {
    // Load both members and admins for a group
    await Future.wait([
      loadGroupMembers(groupId),
      loadGroupAdmins(groupId),
    ]);

    // Recalculate display name for this group after loading members
    await _calculateDisplayNameForGroup(groupId);
  }

  /// Calculate display names for all groups
  Future<void> _calculateDisplayNames(List<GroupData> groups, String currentUserPubkey) async {
    final Map<String, String> displayNames = Map<String, String>.from(
      state.groupDisplayNames ?? {},
    );

    for (final group in groups) {
      final displayName = await _getDisplayNameForGroup(group, currentUserPubkey);
      displayNames[group.mlsGroupId] = displayName;
    }

    state = state.copyWith(groupDisplayNames: displayNames);
  }

  /// Calculate display name for a single group
  Future<void> _calculateDisplayNameForGroup(String groupId) async {
    final group = findGroupById(groupId);
    if (group == null) return;

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) return;

      final displayName = await _getDisplayNameForGroup(group, activeAccountData.pubkey);
      final updatedDisplayNames = Map<String, String>.from(state.groupDisplayNames ?? {});
      updatedDisplayNames[groupId] = displayName;

      state = state.copyWith(groupDisplayNames: updatedDisplayNames);
    } catch (e) {
      _logger.warning('Failed to calculate display name for group $groupId: $e');
    }
  }

  /// Load members for all groups (used during initial group loading)
  Future<void> _loadMembersForAllGroups(List<GroupData> groups) async {
    try {
      final List<Future<void>> loadTasks = [];

      for (final group in groups) {
        // Load members for all groups, especially important for direct messages
        // since they need member data for display names
        loadTasks.add(
          loadGroupMembers(group.mlsGroupId).catchError((e) {
            _logger.warning('Failed to load members for group ${group.mlsGroupId}: $e');
            // Don't let one group failure stop the others
            return;
          }),
        );
      }

      // Execute all member loading in parallel for better performance
      await Future.wait(loadTasks);

      _logger.info('GroupsProvider: Loaded members for ${groups.length} groups');
    } catch (e) {
      _logger.severe('GroupsProvider: Error loading members for groups: $e');
      // Don't throw - we want to continue even if some member loading fails
    }
  }

  /// Get the appropriate display name for a group
  Future<String> _getDisplayNameForGroup(GroupData group, String currentUserPubkey) async {
    // For direct messages, use the other member's name
    if (group.groupType == GroupType.directMessage) {
      try {
        final currentUserNpub = await exportAccountNpub(
          pubkey: await publicKeyFromString(publicKeyString: currentUserPubkey),
        );
        final otherMember = getOtherGroupMember(group.mlsGroupId, currentUserNpub);
        return otherMember?.name ?? 'Direct Message';
      } catch (e) {
        _logger.warning('Failed to get other member name for DM group ${group.mlsGroupId}: $e');
        return 'Direct Message';
      }
    }

    // For regular groups, use the group name
    return group.name;
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

  List<User>? getGroupMembers(String groupId) {
    return state.groupMembers?[groupId];
  }

  List<User>? getGroupAdmins(String groupId) {
    return state.groupAdmins?[groupId];
  }

  String? getGroupDisplayName(String groupId) {
    return state.groupDisplayNames?[groupId];
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

extension GroupMemberUtils on GroupsNotifier {
  User? getOtherGroupMember(String? groupId, String? currentUserNpub) {
    if (groupId == null || currentUserNpub == null) return null;
    final members = getGroupMembers(groupId);
    if (members == null || members.isEmpty) return null;

    return members.firstWhere(
      (member) => member.publicKey != currentUserNpub,
      orElse: () => members.first,
    );
  }

  User? getFirstOtherMember(String? groupId, String? currentUserNpub) {
    if (groupId == null || currentUserNpub == null) return null;
    final members = getGroupMembers(groupId);
    return members?.where((m) => m.publicKey != currentUserNpub).firstOrNull;
  }

  /// Get the display image for a group based on its type
  /// For direct messages, returns the other member's image
  /// For regular groups, returns null (can be extended for group avatars)
  String? getGroupDisplayImage(String groupId, String currentUserNpub) {
    final group = findGroupById(groupId);
    if (group == null) return null;

    // For direct messages, use the other member's image
    if (group.groupType == GroupType.directMessage) {
      final otherMember = getOtherGroupMember(groupId, currentUserNpub);
      return otherMember?.imagePath;
    }

    // For regular groups, could return group avatar in the future
    return null;
  }
}
