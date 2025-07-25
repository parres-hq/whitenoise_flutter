// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/states/group_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/utils/error_handling.dart';

class GroupsNotifier extends Notifier<GroupsState> {
  final _logger = Logger('GroupsNotifier');

  /// Helper function to log WhitenoiseError details synchronously
  /// This is used in catchError blocks where async operations aren't supported
  void _logErrorSync(String methodName, dynamic error) {
    final logMessage = '$methodName - Exception: $error (Type: ${error.runtimeType})';
    _logger.warning(logMessage, error);

    // For WhitenoiseError, we schedule an async operation to get detailed error info
    if (error is WhitenoiseError) {
      Future.microtask(() async {
        try {
          final errorDetails = await whitenoiseErrorToString(error: error);
          _logger.info('$methodName - Detailed WhitenoiseError: $errorDetails');
        } catch (conversionError) {
          _logger.warning('$methodName - WhitenoiseError conversion failed: $conversionError');
        }
      });
    }
  }

  @override
  GroupsState build() {
    // Listen to active account changes and refresh groups automatically
    ref.listen<String?>(activeAccountProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Account switched, clear current groups and load for new account
        // Schedule state changes after the build phase to avoid provider modification errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearGroupData();
          loadGroups();
        });
      } else if (previous != null && next == null) {
        // Account logged out, clear groups
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearGroupData();
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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final groups = await fetchGroups(pubkey: publicKey);

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
      final groupsMap = <String, GroupData>{};
      for (final group in sortedGroups) {
        groupsMap[group.mlsGroupId] = group;
      }
      state = state.copyWith(groups: sortedGroups, groupsMap: groupsMap);

      // Load members for all groups to enable proper display name calculation
      await _loadMembersForAllGroups(groups);

      // Now calculate display names with member data available
      await _calculateDisplayNames(groups, activeAccountData.pubkey);

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
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider.loadGroups - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
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
  Future<GroupData?> _findExistingDirectMessage(String otherUserPubkeyHex) async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) return null;

      final currentUserNpub = await npubFromHexPubkey(hexPubkey: activeAccountData.pubkey);
      final otherUserNpub = await npubFromHexPubkey(hexPubkey: otherUserPubkeyHex);

      final directMessageGroups = getDirectMessageGroups();

      for (final group in directMessageGroups) {
        final members = getGroupMembers(group.mlsGroupId);
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

      // Check if this is a direct message (2 members only: current user + 1 other)
      if (memberPublicKeyHexs.length == 1) {
        final otherUserPubkeyHex = memberPublicKeyHexs.first.trim();
        final existingDM = await _findExistingDirectMessage(otherUserPubkeyHex);

        if (existingDM != null) {
          _logger.info('Returning existing DM group: ${existingDM.mlsGroupId}');
          state = state.copyWith(isLoading: false);
          return existingDM;
        }
      }

      final creatorPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      // Filter out the creator from the members list since they shouldn't be explicitly included
      final creatorPubkeyHex = activeAccountData.pubkey.trim();
      final filteredMemberHexs =
          memberPublicKeyHexs.where((hex) => hex.trim() != creatorPubkeyHex).toList();

      final filteredMemberPubkeys = await Future.wait(
        filteredMemberHexs.map(
          (hexKey) async => await publicKeyFromString(publicKeyString: hexKey.trim()),
        ),
      );
      _logger.info(
        'GroupsProvider: Members pubkeys loaded (excluding creator) - ${filteredMemberPubkeys.length}',
      );

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

      // Debug logging before the createGroup call
      _logger.info('GroupsProvider: Creating group with the following parameters:');
      _logger.info('  - Group name: "$groupName"');
      _logger.info('  - Group description: "$groupDescription"');
      _logger.info('  - Creator pubkey: ${activeAccountData.pubkey}');
      _logger.info('  - Members count (filtered): ${filteredMemberPubkeys.length}');
      _logger.info('  - Admins count: ${combinedAdminKeys.length}');
      _logger.info('  - Member pubkeys (filtered): $filteredMemberHexs');
      _logger.info('  - Admin pubkeys: $adminPublicKeyHexs');

      final newGroup = await createGroup(
        creatorPubkey: creatorPubkey,
        memberPubkeys: filteredMemberPubkeys,
        adminPubkeys: combinedAdminKeys,
        groupName: groupName,
        groupDescription: groupDescription,
      );

      _logger.info('GroupsProvider: Group created successfully - ${newGroup.name}');

      // Instead of calling loadGroups(), update the group's lastMessageAt to put it at the top
      await loadGroups();

      // Set the new group's activity time to now to ensure it appears at the top
      updateGroupActivityTime(newGroup.mlsGroupId, DateTime.now());

      return newGroup;
    } catch (e, st) {
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider.createNewGroup - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
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
          final pubkeyString = await npubFromPublicKey(publicKey: memberPubkey);

          try {
            final metadata = await fetchMetadata(pubkey: memberPubkey);
            if (metadata != null) {
              final user = User.fromMetadata(metadata, pubkeyString);
              members.add(user);
            } else {
              // Create fallback user if metadata is null
              final fallbackUser = User(
                id: pubkeyString,
                displayName: 'Unknown User',
                nip05: '',
                publicKey: pubkeyString,
              );
              members.add(fallbackUser);
            }
          } catch (metadataError) {
            // Log the full exception details with proper WhitenoiseError unpacking
            String logMessage = 'Failed to fetch metadata for member - Exception: ';
            if (metadataError is WhitenoiseError) {
              try {
                final errorDetails = await whitenoiseErrorToString(error: metadataError);
                logMessage += '$errorDetails (Type: ${metadataError.runtimeType})';
              } catch (conversionError) {
                logMessage +=
                    'WhitenoiseError conversion failed: $conversionError (Type: ${metadataError.runtimeType})';
              }
            } else {
              logMessage += '$metadataError (Type: ${metadataError.runtimeType})';
            }
            _logger.warning(logMessage, metadataError);
            // Create a fallback user with minimal info
            final fallbackUser = User(
              id: pubkeyString,
              displayName: 'Unknown User',
              nip05: '',
              publicKey: pubkeyString,
            );
            members.add(fallbackUser);
          }
        } catch (e) {
          // Log the full exception details with proper WhitenoiseError unpacking
          String logMessage = 'Failed to process member pubkey - Exception: ';
          if (e is WhitenoiseError) {
            try {
              final errorDetails = await whitenoiseErrorToString(error: e);
              logMessage += '$errorDetails (Type: ${e.runtimeType})';
            } catch (conversionError) {
              logMessage +=
                  'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
            }
          } else {
            logMessage += '$e (Type: ${e.runtimeType})';
          }
          _logger.severe(logMessage, e);
          // Skip this member if we can't even get the pubkey string
        }
      }

      final updatedGroupMembers = Map<String, List<User>>.from(state.groupMembers ?? {});
      updatedGroupMembers[groupId] = members;

      state = state.copyWith(groupMembers: updatedGroupMembers);
    } catch (e, st) {
      _logger.severe(
        'GroupsProvider.loadGroupMembers - Exception: $e (Type: ${e.runtimeType})',
        e,
        st,
      );
      String errorMessage = 'Failed to load group members';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning(
            'Failed to convert WhitenoiseError to string: $conversionError',
            conversionError,
          );
          errorMessage = 'Failed to load group members due to an internal error';
        }
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
          final pubkeyString = await npubFromPublicKey(publicKey: adminPubkey);

          try {
            final metadata = await fetchMetadata(pubkey: adminPubkey);
            if (metadata != null) {
              final user = User.fromMetadata(metadata, pubkeyString);
              admins.add(user);
            } else {
              // Create fallback user if metadata is null
              final fallbackUser = User(
                id: pubkeyString,
                displayName: 'Unknown User',
                nip05: '',
                publicKey: pubkeyString,
              );
              admins.add(fallbackUser);
            }
          } catch (metadataError) {
            // Log the full exception details with proper WhitenoiseError unpacking
            String logMessage = 'Failed to fetch metadata for admin - Exception: ';
            if (metadataError is WhitenoiseError) {
              try {
                final errorDetails = await whitenoiseErrorToString(error: metadataError);
                logMessage += '$errorDetails (Type: ${metadataError.runtimeType})';
              } catch (conversionError) {
                logMessage +=
                    'WhitenoiseError conversion failed: $conversionError (Type: ${metadataError.runtimeType})';
              }
            } else {
              logMessage += '$metadataError (Type: ${metadataError.runtimeType})';
            }
            _logger.warning(logMessage, metadataError);
            // Create a fallback user with minimal info
            final fallbackUser = User(
              id: pubkeyString,
              displayName: 'Unknown User',
              nip05: '',
              publicKey: pubkeyString,
            );
            admins.add(fallbackUser);
          }
        } catch (e) {
          // Log the full exception details with proper WhitenoiseError unpacking
          String logMessage = 'Failed to process admin pubkey - Exception: ';
          if (e is WhitenoiseError) {
            try {
              final errorDetails = await whitenoiseErrorToString(error: e);
              logMessage += '$errorDetails (Type: ${e.runtimeType})';
            } catch (conversionError) {
              logMessage +=
                  'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
            }
          } else {
            logMessage += '$e (Type: ${e.runtimeType})';
          }
          _logger.severe(logMessage, e);
          // Skip this admin if we can't even get the pubkey string
        }
      }

      final updatedGroupAdmins = Map<String, List<User>>.from(state.groupAdmins ?? {});
      updatedGroupAdmins[groupId] = admins;

      state = state.copyWith(groupAdmins: updatedGroupAdmins);
    } catch (e, st) {
      _logger.severe(
        'GroupsProvider.loadGroupAdmins - Exception: $e (Type: ${e.runtimeType})',
        e,
        st,
      );
      String errorMessage = 'Failed to load group admins';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning(
            'Failed to convert WhitenoiseError to string: $conversionError',
            conversionError,
          );
          errorMessage = 'Failed to load group admins due to an internal error';
        }
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
      String logMessage = 'Failed to calculate display name for group $groupId - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.warning(logMessage, e);
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
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider: Error loading members for groups - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
      // Don't throw - we want to continue even if some member loading fails
    }
  }

  /// Get the appropriate display name for a group
  Future<String> _getDisplayNameForGroup(GroupData group, String currentUserPubkey) async {
    // For direct messages, use the other member's name
    if (group.groupType == GroupType.directMessage) {
      try {
        final currentUserNpub = await npubFromPublicKey(
          publicKey: await publicKeyFromString(publicKeyString: currentUserPubkey),
        );
        final otherMember = getOtherGroupMember(group.mlsGroupId, currentUserNpub);

        if (otherMember == null) {
          _logger.warning(
            'GroupsProvider: Could not find other member for DM group ${group.mlsGroupId}. '
            'This might indicate a data loading issue.',
          );
          return 'Direct Message';
        }

        return otherMember.displayName.isNotEmpty ? otherMember.displayName : 'Unknown User';
      } catch (e) {
        String logMessage =
            'Failed to get other member name for DM group ${group.mlsGroupId} - Exception: ';
        if (e is WhitenoiseError) {
          try {
            final errorDetails = await whitenoiseErrorToString(error: e);
            logMessage += '$errorDetails (Type: ${e.runtimeType})';
          } catch (conversionError) {
            logMessage +=
                'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
          }
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

  GroupData? getGroupById(String groupId) {
    return state.groupsMap?[groupId];
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
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider: Error checking admin status - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.info(logMessage, e);
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

  /// Check for new groups and add them incrementally (for polling)
  Future<void> checkForNewGroups() async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final newGroups = await fetchGroups(pubkey: publicKey);

      final currentGroups = state.groups ?? [];
      final currentGroupIds = currentGroups.map((g) => g.mlsGroupId).toSet();

      // Find truly new groups
      final actuallyNewGroups =
          newGroups.where((group) => !currentGroupIds.contains(group.mlsGroupId)).toList();

      if (actuallyNewGroups.isNotEmpty) {
        // Add new groups to existing list and sort by lastMessageAt (newest first)
        final updatedGroups = [...currentGroups, ...actuallyNewGroups]..sort((a, b) {
          final aTime = a.lastMessageAt;
          final bTime = b.lastMessageAt;

          // Handle null values - groups without messages go to the end
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          // Sort by descending order (newest first)
          return bTime.compareTo(aTime);
        });

        // Update groupsMap with all groups
        final updatedGroupsMap = Map<String, GroupData>.from(state.groupsMap ?? {});
        for (final group in updatedGroups) {
          updatedGroupsMap[group.mlsGroupId] = group;
        }

        state = state.copyWith(groups: updatedGroups, groupsMap: updatedGroupsMap);

        // Load members for new groups only
        await _loadMembersForSpecificGroups(actuallyNewGroups);

        // Calculate display names for new groups
        await _calculateDisplayNamesForSpecificGroups(actuallyNewGroups, activeAccountData.pubkey);

        _logger.info('GroupsProvider: Added ${actuallyNewGroups.length} new groups');
      }
    } catch (e, st) {
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider.checkForNewGroups - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e, st);
    }
  }

  /// Load members for specific groups (used for new groups)
  Future<void> _loadMembersForSpecificGroups(List<GroupData> groups) async {
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
      // Log the full exception details with proper WhitenoiseError unpacking
      String logMessage = 'GroupsProvider: Error loading members for new groups - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
      } else {
        logMessage += '$e (Type: ${e.runtimeType})';
      }
      _logger.severe(logMessage, e);
    }
  }

  /// Calculate display names for specific groups (used for new groups)
  Future<void> _calculateDisplayNamesForSpecificGroups(
    List<GroupData> groups,
    String currentUserPubkey,
  ) async {
    final Map<String, String> displayNames = Map<String, String>.from(
      state.groupDisplayNames ?? {},
    );

    for (final group in groups) {
      final displayName = await _getDisplayNameForGroup(group, currentUserPubkey);
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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final currentUserPubkey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final groupIdObj = await groupIdFromString(hexString: groupId);
      final usersPubkey = await Future.wait(
        membersNpubs.map((userNpub) async {
          return await publicKeyFromString(
            publicKeyString: await hexPubkeyFromNpub(npub: userNpub),
          );
        }),
      );

      await addMembersToGroup(
        pubkey: currentUserPubkey,
        groupId: groupIdObj,
        memberPubkeys: usersPubkey,
      );

      _logger.info(
        'GroupsProvider: Successfully added users ${membersNpubs.join(', ')} to group $groupId',
      );

      // Reload group members to reflect the change
      await loadGroupMembers(groupId);
    } catch (e, st) {
      String logMessage = 'GroupsProvider.addUserToGroup - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      final currentUserPubkey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final groupIdObj = await groupIdFromString(hexString: groupId);

      final usersPubkey = await Future.wait(
        membersNpubs.map((userNpub) async {
          return await publicKeyFromString(
            publicKeyString: await hexPubkeyFromNpub(npub: userNpub),
          );
        }),
      );
      await removeMembersFromGroup(
        pubkey: currentUserPubkey,
        groupId: groupIdObj,
        memberPubkeys: usersPubkey,
      );

      _logger.info(
        'GroupsProvider: Successfully removed users ${membersNpubs.join(', ')} from group $groupId',
      );

      // Reload group members to reflect the change
      await loadGroupMembers(groupId);
    } catch (e, st) {
      String logMessage = 'GroupsProvider.removeFromGroup - Exception: ';
      if (e is WhitenoiseError) {
        try {
          final errorDetails = await whitenoiseErrorToString(error: e);
          logMessage += '$errorDetails (Type: ${e.runtimeType})';
        } catch (conversionError) {
          logMessage +=
              'WhitenoiseError conversion failed: $conversionError (Type: ${e.runtimeType})';
        }
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

  void updateGroupActivityTime(String groupId, DateTime timestamp) {
    final groups = state.groups;
    if (groups == null) return;

    final updatedGroups =
        groups.map((group) {
          if (group.mlsGroupId == groupId) {
            return GroupData(
              mlsGroupId: group.mlsGroupId,
              nostrGroupId: group.nostrGroupId,
              name: group.name,
              description: group.description,
              adminPubkeys: group.adminPubkeys,
              lastMessageId: group.lastMessageId,
              lastMessageAt: BigInt.from(timestamp.millisecondsSinceEpoch),
              groupType: group.groupType,
              epoch: group.epoch,
              state: group.state,
            );
          }
          return group;
        }).toList();

    updatedGroups.sort((a, b) {
      final aTime = a.lastMessageAt;
      final bTime = b.lastMessageAt;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      // Sort by descending order (newest first)
      return bTime.compareTo(aTime);
    });

    // Update groupsMap with the updated groups
    final updatedGroupsMap = <String, GroupData>{};
    for (final group in updatedGroups) {
      updatedGroupsMap[group.mlsGroupId] = group;
    }

    state = state.copyWith(groups: updatedGroups, groupsMap: updatedGroupsMap);
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

    // Use safe filtering - never return the current user as fallback
    final otherMembers = members.where((member) => member.publicKey != currentUserNpub).toList();

    if (otherMembers.isEmpty) {
      _logger.warning(
        'GroupsProvider: No other members found in DM group $groupId. '
        'Total members: ${members.length}, Current user: $currentUserNpub',
      );
      return null;
    }

    return otherMembers.first;
  }

  Future<ContactModel?> getFirstOtherMember(String? groupId, String? currentUserNpub) async {
    if (groupId == null || currentUserNpub == null) return null;
    final members = getGroupMembers(groupId);
    final member = members?.where((m) => m.publicKey != currentUserNpub).firstOrNull;
    if (member == null) return null;
    final hexPubkey = await hexPubkeyFromNpub(npub: member.publicKey);
    final c = await ref.read(metadataCacheProvider.notifier).getContactModel(hexPubkey);

    return c;
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
