// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart' as rust_users;
import 'package:whitenoise/utils/error_handling.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

PubkeyFormatter _defaultPubkeyFormatter({String? pubkey}) => PubkeyFormatter(pubkey: pubkey);

class GroupsNotifier extends Notifier<GroupsState> {
  GroupsNotifier({
    Future<Group> Function({
      required String creatorPubkey,
      required List<String> memberPubkeys,
      required List<String> adminPubkeys,
      required String groupName,
      required String groupDescription,
      required GroupType groupType,
    })?
    createGroupFn,
    PubkeyFormatter Function({String? pubkey})? pubkeyFormatter,
    Future<List<GroupInformation>> Function({
      required String accountPubkey,
      required List<String> groupIds,
    })?
    getGroupsInformationFn,
    Future<List<Group>> Function(GroupType)? getGroupsByTypeFn,
    List<User>? Function(String)? getGroupMembersFn,
  }) : _createGroupFn = createGroupFn ?? createGroup,
       _pubkeyFormatter = pubkeyFormatter ?? _defaultPubkeyFormatter,
       _getGroupsInformationFn = getGroupsInformationFn ?? getGroupsInformations,
       _getGroupsByTypeFn = getGroupsByTypeFn,
       _getGroupMembersFn = getGroupMembersFn;

  final Future<Group> Function({
    required String creatorPubkey,
    required List<String> memberPubkeys,
    required List<String> adminPubkeys,
    required String groupName,
    required String groupDescription,
    required GroupType groupType,
  })
  _createGroupFn;

  final PubkeyFormatter Function({String? pubkey}) _pubkeyFormatter;

  final Future<List<GroupInformation>> Function({
    required String accountPubkey,
    required List<String> groupIds,
  })
  _getGroupsInformationFn;

  final Future<List<Group>> Function(GroupType)? _getGroupsByTypeFn;

  final List<User>? Function(String)? _getGroupMembersFn;

  final _logger = Logger('GroupsNotifier');

  /// Helper function to log Whitenoise ApiError details synchronously
  /// This is used in catchError blocks where async operations aren't supported
  void _logErrorSync(String methodName, dynamic error) {
    final logMessage = '$methodName - Exception: $error (Type: ${error.runtimeType})';
    _logger.warning(logMessage, error);

    // For Whitenoise ApiError, we schedule an async operation to get detailed error info
    if (error is ApiError) {
      Future.microtask(() async {
        final errorDetails = await error.messageText();
        _logger.info('$methodName - Detailed ApiError: $errorDetails');
      });
    }
  }

  @override
  GroupsState build() {
    // Listen to active account changes and refresh groups automatically
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Account switched, clear current groups and load for new account
        // Schedule state changes after the build phase to avoid provider modification errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearGroup();
          loadGroups();
        });
      } else if (previous != null && next == null) {
        // Account logged out, clear groups
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearGroup();
        });
      } else if (previous == null && next != null) {
        // Account logged in, load groups
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadGroups();
        });
      }
    });

    return const GroupsState();
  }

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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';

      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final groups = await activeGroups(pubkey: activePubkey);

      // Sort groups by lastMessageAt in descending order (newest first)
      final sortedGroups = [...groups]..sort((a, b) {
        final aTime = a.lastMessageAt;
        final bTime = b.lastMessageAt;

        // Handle null values - groups without messages go to the end
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        // Sort by descending order (newest first)
        return bTime.compareTo(aTime);
      });

      // First set the groups and create groupsMap
      final groupsMap = <String, Group>{};
      for (final group in sortedGroups) {
        groupsMap[group.mlsGroupId] = group;
      }
      state = state.copyWith(groups: sortedGroups, groupsMap: groupsMap);

      // Load members for all groups to enable proper display name calculation
      await _loadMembersForAllGroups(groups);

      // Load and cache group types for synchronous access
      await _loadGroupTypesForAllGroups(groups);

      // Load and cache group image paths
      await _loadGroupImagePaths(groups);

      // Now calculate display names with member data available
      await _calculateDisplayNames(groups);

      // Schedule message loading after the current build cycle completes
      Future.microtask(() async {
        await ref
            .read(chatProvider.notifier)
            .loadMessagesForGroups(
              groups.map((g) => g.mlsGroupId).toList(),
            );
      });

      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      // Log the full exception details with proper Whitenoise ApiError unpacking
      String logMessage = 'GroupsProvider.loadGroups - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);

      final errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage:
            'Failed to load groups due to an internal error. Please check your connection and try again.',
        context: 'loadGroups',
      );

      state = state.copyWith(error: errorMessage, isLoading: false);
    }
  }

  /// Find an existing direct message group between the current user and another user
  Future<Group?> _findExistingDirectMessage(String otherUserPubkeyHex) async {
    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) return null;

      final currentUserNpub = _pubkeyFormatter(pubkey: activePubkey).toNpub();
      final otherUserNpub = _pubkeyFormatter(pubkey: otherUserPubkeyHex).toNpub();

      final directMessageGroups = await getDirectMessageGroups();

      for (final group in directMessageGroups) {
        final members =
            _getGroupMembersFn?.call(group.mlsGroupId) ?? getGroupMembers(group.mlsGroupId);
        if (members != null && members.length == 2) {
          final memberPubkeys = members.map((m) => m.publicKey).toSet();
          if (memberPubkeys.contains(currentUserNpub) && memberPubkeys.contains(otherUserNpub)) {
            _logger.info('Found existing DM group: ${group.mlsGroupId}');
            return group;
          }
        }
      }

      return null;
    } catch (e) {
      _logger.warning('Error finding existing DM: $e');
      return null;
    }
  }

  Future<Group?> createNewGroup({
    required String groupName,
    required String groupDescription,
    required List<String> memberPublicKeyHexs,
    required List<String> adminPublicKeyHexs,
    bool isDm = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return null;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';

      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return null;
      }

      // Check if this is a direct message (2 members only: current user + 1 other)
      // Only check for existing DMs when explicitly creating a DM
      if (isDm && memberPublicKeyHexs.length == 1) {
        final otherUserPubkeyHex = memberPublicKeyHexs.first.trim();
        final existingDM = await _findExistingDirectMessage(otherUserPubkeyHex);

        if (existingDM != null) {
          _logger.info('Returning existing DM group: ${existingDM.mlsGroupId}');
          state = state.copyWith(isLoading: false);
          return existingDM;
        }
      }

      // Filter out the creator from the members list since they shouldn't be explicitly included
      final creatorPubkeyHex = activePubkey.trim();
      final filteredMemberHexs =
          memberPublicKeyHexs.where((hex) => hex.trim() != creatorPubkeyHex).toList();

      final filteredMemberPubkeys = filteredMemberHexs.map((hexKey) => hexKey.trim()).toList();
      _logger.info(
        'GroupsProvider: Members pubkeys loaded (excluding creator) - ${filteredMemberPubkeys.length}',
      );
      final resolvedAdminPublicKeys =
          adminPublicKeyHexs.toSet().map((hexKey) => hexKey.trim()).toList();
      final combinedAdminKeys = {activePubkey, ...resolvedAdminPublicKeys}.toList();
      _logger.info('GroupsProvider: Admin pubkeys loaded - ${combinedAdminKeys.length}');

      // Debug logging before the createGroup call
      _logger.info('GroupsProvider: Creating group with the following parameters:');
      _logger.info('  - Group name: "$groupName"');
      _logger.info('  - Group description: "$groupDescription"');
      _logger.info('  - Creator pubkey: $activePubkey');
      _logger.info('  - Members count (filtered): ${filteredMemberPubkeys.length}');
      _logger.info('  - Admins count: ${combinedAdminKeys.length}');
      _logger.info('  - Member pubkeys (filtered): $filteredMemberHexs');
      _logger.info('  - Admin pubkeys: $adminPublicKeyHexs');

      final newGroup = await _createGroupFn(
        creatorPubkey: activePubkey,
        memberPubkeys: filteredMemberPubkeys,
        adminPubkeys: combinedAdminKeys,
        groupName: groupName,
        groupDescription: groupDescription,
        groupType: isDm ? GroupType.directMessage : GroupType.group,
      );

      _logger.info('GroupsProvider: Group created successfully - ${newGroup.name}');

      // Instead of calling loadGroups(), update the group's lastMessageAt to put it at the top
      await loadGroups();

      // Set the new group's activity time to now to ensure it appears at the top
      updateGroupActivityTime(newGroup.mlsGroupId, DateTime.now());

      return newGroup;
    } catch (e, st) {
      // Log the full exception details with proper Whitenoise ApiError unpacking
      String logMessage = 'GroupsProvider.createNewGroup - Exception: ';
      if (e is ApiError) {
        final errorDetails = e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);

      // Try to get a user-friendly error message, but with fallback
      String errorMessage;
      try {
        errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
          error: e,
          stackTrace: st,
          fallbackMessage: ErrorHandlingUtils.getGroupCreationFallbackMessage(),
          context: 'createNewGroup',
        );
      } catch (errorHandlingError) {
        // If error handling fails, use a simple fallback
        _logger.severe(
          'GroupsProvider.createNewGroup - Error handling failed: $errorHandlingError',
          errorHandlingError,
        );

        errorMessage = 'Failed to create group due to an internal error. Please try again.';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return null;
    }
  }

  Future<void> loadGroupMembers(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final memberPubkeys = await groupMembers(pubkey: activePubkey, groupId: groupId);

      _logger.info('GroupsProvider: Loaded ${memberPubkeys.length} members for group $groupId');

      // Fetch metadata for each member and create User objects
      final List<domain_user.User> members = [];
      for (final memberPubkey in memberPubkeys) {
        try {
          final npub = _pubkeyFormatter(pubkey: memberPubkey).toNpub() ?? '';

          // First try to get from follows
          final followsNotifier = ref.read(followsProvider.notifier);
          final existingFollow = followsNotifier.findFollowByPubkey(memberPubkey);

          if (existingFollow != null) {
            _logger.info('Found member $npub in follows cache');
            // Convert Rust User to domain User
            final domainUser = domain_user.User.fromMetadata(existingFollow.metadata, npub);
            members.add(domainUser);
            continue;
          }

          // If not in follows, fetch directly from API
          try {
            final metadata = await rust_users.userMetadata(pubkey: memberPubkey);
            final user = domain_user.User.fromMetadata(metadata, npub);
            members.add(user);
          } catch (metadataError) {
            // Log the full exception details with proper Whitenoise ApiError unpacking
            String logMessage = 'Failed to fetch metadata for member - Exception: ';
            if (metadataError is ApiError) {
              final errorDetails = await metadataError.messageText();
              logMessage += '$errorDetails (Type: ${metadataError.runtimeType})';
            } else {
              logMessage += '$metadataError (Type: ${metadataError.runtimeType})';
            }
            _logger.warning(logMessage, metadataError);
            // Create a fallback user with minimal info
            final fallbackUser = domain_user.User(
              id: npub,
              displayName: 'shared.unknownUser'.tr(),
              nip05: '',
              publicKey: npub,
            );
            members.add(fallbackUser);
          }
        } catch (e) {
          // Log the full exception details with proper ApiError unpacking
          String logMessage = 'Failed to process member pubkey - Exception: ';
          if (e is ApiError) {
            final errorDetails = await e.messageText();
            logMessage += '$errorDetails (Type: ${e.runtimeType})';
          } else {
            logMessage += '$e (Type: ${e.runtimeType})';
          }
          _logger.severe(logMessage, e);
          // Skip this member if we can't even get the pubkey string
        }
      }

      final updatedGroupMembers = Map<String, List<domain_user.User>>.from(
        state.groupMembers ?? {},
      );
      updatedGroupMembers[groupId] = members;

      state = state.copyWith(groupMembers: updatedGroupMembers);
    } catch (e, st) {
      _logger.severe(
        'GroupsProvider.loadGroupMembers - Exception: $e (Type: ${e.runtimeType})',
        e,
        st,
      );
      String errorMessage = 'Failed to load group members';
      if (e is ApiError) {
        errorMessage = await e.messageText();
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<void> loadGroupAdmins(String groupId) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final adminPubkeys = await groupAdmins(pubkey: activePubkey, groupId: groupId);

      _logger.info('GroupsProvider: Loaded ${adminPubkeys.length} admins for group $groupId');

      // Fetch metadata for each admin and create User objects
      final List<domain_user.User> admins = [];
      for (final adminPubkey in adminPubkeys) {
        try {
          final npub = _pubkeyFormatter(pubkey: adminPubkey).toNpub() ?? '';

          try {
            final metadata = await rust_users.userMetadata(pubkey: adminPubkey);
            final user = domain_user.User.fromMetadata(metadata, npub);
            admins.add(user);
          } catch (metadataError) {
            // Log the full exception details with proper ApiError unpacking
            String logMessage = 'Failed to fetch metadata for admin - Exception: ';
            if (metadataError is ApiError) {
              final errorDetails = await metadataError.messageText();
              logMessage += '$errorDetails (Type: ${metadataError.runtimeType})';
            } else {
              logMessage += '$metadataError (Type: ${metadataError.runtimeType})';
            }
            _logger.warning(logMessage, metadataError);
            // Create a fallback user with minimal info
            final fallbackUser = domain_user.User(
              id: npub,
              displayName: 'shared.unknownUser'.tr(),
              nip05: '',
              publicKey: npub,
            );
            admins.add(fallbackUser);
          }
        } catch (e) {
          // Log the full exception details with proper ApiError unpacking
          String logMessage = 'Failed to process admin pubkey - Exception: ';
          if (e is ApiError) {
            final errorDetails = e.messageText();
            logMessage += '$errorDetails (Type: ${e.runtimeType})';
          } else {
            logMessage += '$e (Type: ${e.runtimeType})';
          }
          _logger.severe(logMessage, e);
          // Skip this admin if we can't even get the pubkey string
        }
      }

      final updatedGroupAdmins = Map<String, List<domain_user.User>>.from(state.groupAdmins ?? {});
      updatedGroupAdmins[groupId] = admins;

      state = state.copyWith(groupAdmins: updatedGroupAdmins);
    } catch (e, st) {
      _logger.severe(
        'GroupsProvider.loadGroupAdmins - Exception: $e (Type: ${e.runtimeType})',
        e,
        st,
      );
      String errorMessage = 'Failed to load group admins';
      if (e is ApiError) {
        errorMessage = await e.messageText();
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
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
  Future<void> _calculateDisplayNames(List<Group> groups) async {
    final Map<String, String> displayNames = Map<String, String>.from(
      state.groupDisplayNames ?? {},
    );

    for (final group in groups) {
      final displayName = await _getDisplayNameForGroup(group);
      displayNames[group.mlsGroupId] = displayName;
    }

    state = state.copyWith(groupDisplayNames: displayNames);
  }

  /// Calculate display name for a single group
  Future<void> _calculateDisplayNameForGroup(String groupId) async {
    final group = findGroupById(groupId);
    if (group == null) return;

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) return;

      final displayName = await _getDisplayNameForGroup(group);
      final updatedDisplayNames = Map<String, String>.from(state.groupDisplayNames ?? {});
      updatedDisplayNames[groupId] = displayName;

      state = state.copyWith(groupDisplayNames: updatedDisplayNames);
    } catch (e) {
      String logMessage = 'Failed to calculate display name for group $groupId - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.warning(logMessage, e);
    }
  }

  /// Load and cache group types for all groups
  Future<void> _loadGroupTypesForAllGroups(List<Group> groups) async {
    try {
      final Map<String, GroupType> groupTypes = Map<String, GroupType>.from(
        state.groupTypes ?? {},
      );

      final List<Future<void>> loadTasks = [];
      final activePubkey = ref.read(activePubkeyProvider);
      if (activePubkey == null || activePubkey.isEmpty) return;

      for (final group in groups) {
        loadTasks.add(
          group
              .groupType(accountPubkey: activePubkey)
              .then((groupType) {
                groupTypes[group.mlsGroupId] = groupType;
              })
              .catchError((e) {
                _logErrorSync('Failed to load group type for group ${group.mlsGroupId}', e);
                // Set a default fallback type
                groupTypes[group.mlsGroupId] = GroupType.group;
              }),
        );
      }

      // Execute all group type loading in parallel for better performance
      await Future.wait(loadTasks);

      // Update state with the cached group types
      state = state.copyWith(groupTypes: groupTypes);

      _logger.info('GroupsProvider: Loaded group types for ${groups.length} groups');
    } catch (e) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider: Error loading group types - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
      // Don't throw - we want to continue even if some group type loading fails
    }
  }

  /// Load and cache group image paths for all groups
  Future<void> _loadGroupImagePaths(List<Group> groups) async {
    try {
      final Map<String, String> groupImagePaths = Map<String, String>.from(
        state.groupImagePaths ?? {},
      );

      final List<Future<void>> loadTasks = [];
      final activePubkey = ref.read(activePubkeyProvider);
      if (activePubkey == null || activePubkey.isEmpty) return;

      for (final group in groups) {
        loadTasks.add(
          getGroupImagePath(
                accountPubkey: activePubkey,
                groupId: group.mlsGroupId,
              )
              .then((imagePath) {
                if (imagePath != null && imagePath.isNotEmpty) {
                  groupImagePaths[group.mlsGroupId] = imagePath;
                }
              })
              .catchError((e) {
                _logErrorSync('Failed to load image path for group ${group.mlsGroupId}', e);
                // Skip this group if image loading fails
              }),
        );
      }

      // Execute all image path loading in parallel for better performance
      await Future.wait(loadTasks);

      // Update state with the cached image paths
      state = state.copyWith(groupImagePaths: groupImagePaths);

      _logger.info('GroupsProvider: Loaded image paths for ${groupImagePaths.length} groups');
    } catch (e) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider: Error loading group image paths - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
      // Don't throw - we want to continue even if some image loading fails
    }
  }

  /// Load members for all groups (used during initial group loading)
  Future<void> _loadMembersForAllGroups(List<Group> groups) async {
    try {
      final List<Future<void>> loadTasks = [];

      for (final group in groups) {
        // Load members for all groups, especially important for direct messages
        // since they need member data for display names
        loadTasks.add(
          loadGroupMembers(group.mlsGroupId).catchError((e) {
            _logErrorSync('Failed to load members for group ${group.mlsGroupId}', e);
            // Don't let one group failure stop the others
            return;
          }),
        );
      }

      // Execute all member loading in parallel for better performance
      await Future.wait(loadTasks);

      _logger.info('GroupsProvider: Loaded members for ${groups.length} groups');
    } catch (e) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider: Error loading members for groups - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
      // Don't throw - we want to continue even if some member loading fails
    }
  }

  /// Get the appropriate display name for a group
  Future<String> _getDisplayNameForGroup(Group group) async {
    // For direct messages, use the other member's name
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) return '';
    final groupInformation = await getGroupInformation(
      accountPubkey: activePubkey,
      groupId: group.mlsGroupId,
    );
    if (groupInformation.groupType == GroupType.directMessage) {
      try {
        final otherMember = getOtherGroupMember(group.mlsGroupId);

        if (otherMember == null) {
          _logger.warning(
            'GroupsProvider: Could not find other member for DM group ${group.mlsGroupId}. '
            'This might indicate a data loading issue.',
          );
          return 'Direct Message';
        }

        return otherMember.displayName.isNotEmpty
            ? otherMember.displayName
            : 'shared.unknownUser'.tr();
      } catch (e) {
        String logMessage =
            'Failed to get other member name for DM group ${group.mlsGroupId} - Exception: ';
        if (e is ApiError) {
          final errorDetails = await e.messageText();
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } else {
          logMessage += '$e (Type: ${e.runtimeType})';
        }
        _logger.warning(logMessage, e);
        return 'Direct Message';
      }
    }

    // For regular groups, use the group name
    return group.name;
  }

  Future<Map<String, GroupInformation>> _getGroupInformationsMap(List<Group> groups) async {
    final groupIds = groups.map((group) => group.mlsGroupId).toList();
    final groupInformationsMap = <String, GroupInformation>{};
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) return groupInformationsMap;
    final groupInformations = await _getGroupsInformationFn(
      accountPubkey: activePubkey,
      groupIds: groupIds,
    );
    for (int i = 0; i < groupIds.length && i < groupInformations.length; i++) {
      groupInformationsMap[groupIds[i]] = groupInformations[i];
    }
    return groupInformationsMap;
  }

  Future<List<Group>> getGroupsByType(GroupType type) async {
    final groups = state.groups;
    if (groups == null) return [];

    final groupInformationsMap = await _getGroupInformationsMap(groups);

    return groups
        .where((group) => groupInformationsMap[group.mlsGroupId]?.groupType == type)
        .toList();
  }

  List<Group> getActiveGroups() {
    final groups = state.groups;
    if (groups == null) return [];
    return groups.where((group) => (group as Group?)?.state == GroupState.active).toList();
  }

  Future<List<Group>> getDirectMessageGroups() async {
    if (_getGroupsByTypeFn != null) {
      return await _getGroupsByTypeFn(GroupType.directMessage);
    }
    return await getGroupsByType(GroupType.directMessage);
  }

  Future<List<Group>> getRegularGroups() async {
    return await getGroupsByType(GroupType.group);
  }

  Group? findGroupById(String groupId) {
    // First try to get from groupsMap for faster lookup
    final groupsMap = state.groupsMap;
    if (groupsMap != null) {
      final group = groupsMap[groupId];
      if (group != null) return group;
    }

    // Fallback to searching through groups list
    final groups = state.groups;
    if (groups == null) return null;

    try {
      return groups.firstWhere(
        (group) => (group as Group?)?.mlsGroupId == groupId || (group).nostrGroupId == groupId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<GroupType> getGroupType(Group group) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    final groupInformation = await getGroupInformation(
      accountPubkey: activePubkey,
      groupId: group.mlsGroupId,
    );

    return groupInformation.groupType;
  }

  Future<GroupType> getGroupTypeById(String groupId) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    final groupInformation = await getGroupInformation(
      accountPubkey: activePubkey,
      groupId: groupId,
    );

    return groupInformation.groupType;
  }

  List<domain_user.User>? getGroupMembers(String groupId) {
    return state.groupMembers?[groupId];
  }

  List<domain_user.User>? getGroupAdmins(String groupId) {
    return state.groupAdmins?[groupId];
  }

  String? getGroupDisplayName(String groupId) {
    return state.groupDisplayNames?[groupId];
  }

  Group? getGroupById(String groupId) {
    return state.groupsMap?[groupId];
  }

  /// Get cached group type synchronously
  /// Returns null if group type is not cached yet
  GroupType? getCachedGroupType(String groupId) {
    return state.groupTypes?[groupId];
  }

  /// Get cached group image path synchronously
  /// Returns null if group image path is not cached yet
  String? getCachedGroupImagePath(String groupId) {
    return state.groupImagePaths?[groupId];
  }

  /// Reload image path for a specific group
  /// Useful when a group's image has been updated
  Future<void> reloadGroupImagePath(String groupId) async {
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) return;

    try {
      final imagePath = await getGroupImagePath(
        accountPubkey: activePubkey,
        groupId: groupId,
      );

      if (imagePath != null && imagePath.isNotEmpty) {
        final updatedPaths = Map<String, String>.from(state.groupImagePaths ?? {});
        updatedPaths[groupId] = imagePath;
        state = state.copyWith(groupImagePaths: updatedPaths);
        _logger.info('Reloaded image path for group $groupId');
      }
    } catch (e) {
      _logger.warning('Failed to reload image path for group $groupId: $e');
    }
  }

  Future<bool> isCurrentUserAdmin(String groupId) async {
    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) return false;

      final group = findGroupById(groupId);
      if (group == null) return false;

      return group.adminPubkeys.contains(activePubkey);
    } catch (e) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider: Error checking admin status - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.info(logMessage, e);
      return false;
    }
  }

  void clearGroup() {
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

  /// Check for new groups and add them incrementally (for polling)
  Future<void> checkForNewGroups() async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        return;
      }

      final newGroups = await activeGroups(pubkey: activePubkey);

      final currentGroups = state.groups ?? [];
      final currentGroupIds =
          currentGroups.map((g) => (g as Group?)?.mlsGroupId).whereType<String>().toSet();

      // Find truly new groups
      final actuallyNewGroups =
          newGroups.where((group) => !currentGroupIds.contains(group.mlsGroupId)).toList();

      if (actuallyNewGroups.isNotEmpty) {
        // Add new groups to existing list and sort by lastMessageAt (newest first)
        final updatedGroups = [...currentGroups, ...actuallyNewGroups]..sort((a, b) {
          final aTime = (a as Group?)?.lastMessageAt;
          final bTime = (b as Group?)?.lastMessageAt;

          // Handle null values - groups without messages go to the end
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          // Sort by descending order (newest first)
          return bTime.compareTo(aTime);
        });

        // Update groupsMap with all groups
        final updatedGroupsMap = Map<String, Group>.from(state.groupsMap ?? {});
        for (final group in updatedGroups) {
          updatedGroupsMap[group.mlsGroupId] = group;
        }

        state = state.copyWith(groups: updatedGroups, groupsMap: updatedGroupsMap);

        // Load members for new groups only
        await _loadMembersForSpecificGroups(actuallyNewGroups);

        // Load and cache group types for new groups
        await _loadGroupTypesForAllGroups(actuallyNewGroups);

        // Load and cache group image paths for new groups
        await _loadGroupImagePaths(actuallyNewGroups);

        // Calculate display names for new groups
        await _calculateDisplayNamesForSpecificGroups(actuallyNewGroups);

        _logger.info('GroupsProvider: Added ${actuallyNewGroups.length} new groups');
      }
    } catch (e, st) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider.checkForNewGroups - Exception: ';
      if (e is ApiError) {
        final errorDetails = e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);
    }
  }

  /// Load members for specific groups (used for new groups)
  Future<void> _loadMembersForSpecificGroups(List<Group> groups) async {
    try {
      final List<Future<void>> loadTasks = [];

      for (final group in groups) {
        loadTasks.add(
          loadGroupMembers(group.mlsGroupId).catchError((e) {
            _logErrorSync('Failed to load members for new group ${group.mlsGroupId}', e);
            return;
          }),
        );
      }

      await Future.wait(loadTasks);
    } catch (e) {
      // Log the full exception details with proper ApiError unpacking
      String logMessage = 'GroupsProvider: Error loading members for new groups - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
    }
  }

  /// Calculate display names for specific groups (used for new groups)
  Future<void> _calculateDisplayNamesForSpecificGroups(
    List<Group> groups,
  ) async {
    final Map<String, String> displayNames = Map<String, String>.from(
      state.groupDisplayNames ?? {},
    );

    for (final group in groups) {
      final displayName = await _getDisplayNameForGroup(group);
      displayNames[group.mlsGroupId] = displayName;
    }

    state = state.copyWith(groupDisplayNames: displayNames);
  }

  Future<void> addToGroup({
    required String groupId,
    required List<String> membersNpubs,
  }) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final usersPubkeyHex =
          membersNpubs.map((userNpub) {
            return _pubkeyFormatter(pubkey: userNpub).toHex() ?? '';
          }).toList();

      await addMembersToGroup(
        pubkey: activePubkey,
        groupId: groupId,
        memberPubkeys: usersPubkeyHex,
      );

      _logger.info(
        'GroupsProvider: Successfully added users ${membersNpubs.join(', ')} to group $groupId',
      );

      // Reload group members to reflect the change
      await loadGroupMembers(groupId);
    } catch (e, st) {
      String logMessage = 'GroupsProvider.addUserToGroup - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);

      final errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'Failed to add user to group. Please try again.',
        context: 'addUserToGroup',
      );

      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }

  Future<void> removeFromGroup({
    required String groupId,
    required List<String> membersNpubs,
  }) async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final usersPubkeyHex =
          membersNpubs.map((userNpub) {
            return _pubkeyFormatter(pubkey: userNpub).toHex() ?? '';
          }).toList();

      await removeMembersFromGroup(
        pubkey: activePubkey,
        groupId: groupId,
        memberPubkeys: usersPubkeyHex,
      );

      _logger.info(
        'GroupsProvider: Successfully removed users ${membersNpubs.join(', ')} from group $groupId',
      );

      // Reload group members to reflect the change
      await loadGroupMembers(groupId);
    } catch (e, st) {
      String logMessage = 'GroupsProvider.removeFromGroup - Exception: ';
      if (e is ApiError) {
        final errorDetails = await e.messageText();
        logMessage += '$errorDetails (Type: ${e.runtimeType})';
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);

      final errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'Failed to remove user from group. Please try again.',
        context: 'removeFromGroup',
      );

      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }

  Future<void> updateGroupActivityTime(String groupId, DateTime timestamp) async {
    final groups = state.groups;
    if (groups == null) return;

    final updatedGroups =
        groups.map((group) {
          if ((group as Group?)?.mlsGroupId == groupId) {
            final g = group;
            return Group(
              mlsGroupId: g.mlsGroupId,
              nostrGroupId: g.nostrGroupId,
              name: g.name,
              description: g.description,
              imageHash: g.imageHash,
              imageKey: g.imageKey,
              adminPubkeys: g.adminPubkeys,
              lastMessageId: g.lastMessageId,
              lastMessageAt: timestamp,
              epoch: g.epoch,
              state: g.state,
            );
          }
          return group;
        }).toList();

    updatedGroups.sort((a, b) {
      final aTime = (a).lastMessageAt;
      final bTime = (b).lastMessageAt;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      // Sort by descending order (newest first)
      return bTime.compareTo(aTime);
    });

    // Update groupsMap with the updated groups
    final updatedGroupsMap = <String, Group>{};
    for (final group in updatedGroups) {
      final g = group;
      updatedGroupsMap[g.mlsGroupId] = g;
    }

    state = state.copyWith(groups: updatedGroups, groupsMap: updatedGroupsMap);
  }

  /// Update group information (name and description) optimistically
  void _updateGroupInfo(String groupId, {String? name, String? description}) {
    final groups = state.groups;
    final groupsMap = state.groupsMap;
    if (groups == null || groupsMap == null) return;

    final updatedGroups =
        groups.map((group) {
          if ((group as Group?)?.mlsGroupId == groupId) {
            final g = group;
            return Group(
              mlsGroupId: g.mlsGroupId,
              nostrGroupId: g.nostrGroupId,
              name: name ?? g.name,
              description: description ?? g.description,
              imageHash: g.imageHash,
              imageKey: g.imageKey,
              adminPubkeys: g.adminPubkeys,
              lastMessageId: g.lastMessageId,
              lastMessageAt: g.lastMessageAt,
              epoch: g.epoch,
              state: g.state,
            );
          }
          return group;
        }).toList();

    // Update groupsMap with the updated groups
    final updatedGroupsMap = <String, Group>{};
    for (final group in updatedGroups) {
      final g = group;
      updatedGroupsMap[g.mlsGroupId] = g;
    }

    // Update groupDisplayNames if name was changed
    Map<String, String>? updatedDisplayNames;
    if (name != null) {
      updatedDisplayNames = Map<String, String>.from(state.groupDisplayNames ?? {});
      updatedDisplayNames[groupId] = name;
    }

    state = state.copyWith(
      groups: updatedGroups,
      groupsMap: updatedGroupsMap,
      groupDisplayNames: updatedDisplayNames ?? state.groupDisplayNames,
    );
  }

  /// Update group data (name and description) with backend sync
  Future<void> updateGroup({
    required String groupId,
    required String accountPubkey,
    String? name,
    String? description,
  }) async {
    final group = state.groupsMap?[groupId];
    if (group == null) {
      throw Exception('Group not found');
    }

    final trimmedName = name?.trim();
    final trimmedDescription = description?.trim();

    final nameChanged = trimmedName != null && trimmedName != group.name;
    final descriptionChanged =
        trimmedDescription != null && trimmedDescription != group.description;

    if (!nameChanged && !descriptionChanged) {
      return;
    }

    try {
      final groupData = FlutterGroupDataUpdate(
        name: nameChanged ? trimmedName : null,
        description: descriptionChanged ? trimmedDescription : null,
      );

      await group.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groupData,
      );

      // Update provider state optimistically after successful backend call
      _updateGroupInfo(groupId, name: trimmedName, description: trimmedDescription);
    } catch (e, st) {
      _logger.severe(
        'GroupsProvider.updateGroup - Exception: $e (Type: ${e.runtimeType})',
        e,
        st,
      );

      String errorMessage = 'Failed to update group';
      if (e is ApiError) {
        errorMessage = await e.messageText();
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }
}

final groupsProvider = NotifierProvider<GroupsNotifier, GroupsState>(
  GroupsNotifier.new,
);

extension GroupMemberUtils on GroupsNotifier {
  domain_user.User? getOtherGroupMember(String? groupId) {
    if (groupId == null) return null;
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) return null;
    final members = getGroupMembers(groupId);
    if (members == null || members.isEmpty) return null;

    final hexActivePubkey = _pubkeyFormatter(pubkey: activePubkey).toHex();
    final otherMembers =
        members
            .where(
              (member) => _pubkeyFormatter(pubkey: member.publicKey).toHex() != hexActivePubkey,
            )
            .toList();
    final npubActivePubkey = _pubkeyFormatter(pubkey: activePubkey).toNpub();
    if (otherMembers.isEmpty) {
      _logger.warning(
        'GroupsProvider: No other members found in DM group $groupId. '
        'Total members: ${members.length}, Current user: $npubActivePubkey',
      );
      return null;
    }

    return otherMembers.first;
  }

  /// Get the display image for a group based on its type
  /// For direct messages, returns the other member's image
  /// For regular groups, returns the cached group image path
  String? getGroupDisplayImage(String groupId) {
    final group = findGroupById(groupId);
    if (group == null) return null;

    // Use cached group type for synchronous access
    final groupType = getCachedGroupType(groupId);

    // If group type is not cached yet, default to group type for safety
    // This can happen during initial loading before group types are cached
    if (groupType == null) {
      _logger.info('Group type not cached yet for group $groupId, defaulting to group type');
      return null;
    }

    // For direct messages, use the other member's image
    if (groupType == GroupType.directMessage) {
      final otherMember = getOtherGroupMember(groupId);
      return otherMember?.imagePath;
    }

    // For regular groups, return the cached group image path
    return getCachedGroupImagePath(groupId);
  }
}
