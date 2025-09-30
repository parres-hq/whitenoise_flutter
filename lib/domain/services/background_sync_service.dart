import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';
import 'package:whitenoise/domain/services/notification_id_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncService {
  static final _logger = Logger('BackgroundSyncService');

  static const String messagesSyncTask = 'com.whitenoise.messages_sync';
  static const String invitesSyncTask = 'com.whitenoise.invites_sync';
  static const String metadataRefreshTask = 'com.whitenoise.metadata_refresh';
  static const String _bgTasksRegisteredKey = 'bg_tasks_registered';
  static const String _taskFlagPrefix = 'bg_task_registered';
  static const String _lastRegisteredPrefix = 'bg_last_registered_ts';

  static const Duration _messagesSyncFrequency = Duration(minutes: 15);
  static const Duration _invitesSyncFrequency = Duration(minutes: 15);
  static const Duration _metadataRefreshFrequency = Duration(hours: 24);

  // Notification constants
  static const String _notificationTypeNewMessage = 'new_message';
  static const String _notificationTypeInvitesSync = 'invites_sync';
  static const String _notificationTitleNewInvitations = 'New Invitations';
  static const String _notificationTitleDirectMessage = 'Direct Message';
  static const String _notificationTitleUnknownGroup = 'Unknown Group';
  static const String _notificationTitleGroupChat = 'Group Chat';

  // Sync time constants
  static const Duration _messageFilterBufferSeconds = Duration(seconds: 1);
  static const Duration _taskDelaySeconds = Duration(seconds: 1);

  // Display name constants
  static const int _pubkeyDisplayLength = 8;

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.fine('BackgroundSyncService already initialized');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      _isInitialized = true;
      _logger.info('BackgroundSyncService initialized successfully');
    } catch (e) {
      _logger.severe('BackgroundSyncService initialization', e);
      rethrow;
    }
  }

  static Future<void> registerAllTasks() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
      if (activePubkey == null || activePubkey.isEmpty) {
        _logger.warning('Background tasks registration skipped: no active account');
        return;
      }

      bool messagesRegistered = false;
      bool invitesRegistered = false;
      bool metadataRegistered = false;

      await Workmanager().registerPeriodicTask(
        'messages_sync',
        messagesSyncTask,
        frequency: _messagesSyncFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      messagesRegistered = true;
      await _setTaskFlag(activePubkey: activePubkey, taskName: messagesSyncTask, value: true);

      try {
        await Workmanager().registerPeriodicTask(
          'invites_sync',
          invitesSyncTask,
          frequency: _invitesSyncFrequency,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
        invitesRegistered = true;
        await _setTaskFlag(activePubkey: activePubkey, taskName: invitesSyncTask, value: true);
      } catch (e) {
        _logger.severe('Register invites sync task', e);
      }

      try {
        await Workmanager().registerPeriodicTask(
          'metadata_refresh',
          metadataRefreshTask,
          frequency: _metadataRefreshFrequency,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
        metadataRegistered = true;
        await _setTaskFlag(
          activePubkey: activePubkey,
          taskName: metadataRefreshTask,
          value: true,
        );
      } catch (e) {
        _logger.severe('Register metadata refresh task', e);
      }

      _logger.info('All background tasks registered successfully');
      try {
        final prefs = await SharedPreferences.getInstance();
        final bool allRegistered = messagesRegistered && invitesRegistered && metadataRegistered;
        await prefs.setBool('$_bgTasksRegisteredKey:$activePubkey', allRegistered);
        await prefs.setInt(
          '$_lastRegisteredPrefix:$activePubkey',
          DateTime.now().millisecondsSinceEpoch,
        );
        // Clear legacy/global flag to avoid misleading state from prior versions
        await prefs.remove(_bgTasksRegisteredKey);
      } catch (e) {
        _logger.warning('Persist bg tasks registered flag', e);
      }
    } catch (e) {
      _logger.severe('Background tasks registration', e);
      rethrow;
    }
  }

  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All background tasks cancelled');
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
        if (activePubkey != null && activePubkey.isNotEmpty) {
          await _setTaskFlag(activePubkey: activePubkey, taskName: messagesSyncTask, value: false);
          await _setTaskFlag(activePubkey: activePubkey, taskName: invitesSyncTask, value: false);
          await _setTaskFlag(
            activePubkey: activePubkey,
            taskName: metadataRefreshTask,
            value: false,
          );
          await prefs.setBool('$_bgTasksRegisteredKey:$activePubkey', false);
          await prefs.remove('$_lastRegisteredPrefix:$activePubkey');
        }
        await prefs.setBool(_bgTasksRegisteredKey, false);
      } catch (e) {
        _logger.warning('Clear bg tasks registered flag', e);
      }
    } catch (e) {
      _logger.severe('Background tasks cancellation', e);
    }
  }

  static Future<List<String>> getRegisteredTasks() async {
    try {
      final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
      if (activePubkey == null || activePubkey.isEmpty) return [];
      final prefs = await SharedPreferences.getInstance();
      final List<String> registered = [];
      if (prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: messagesSyncTask)) ==
          true) {
        registered.add(messagesSyncTask);
      }
      if (prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: invitesSyncTask)) ==
          true) {
        registered.add(invitesSyncTask);
      }
      if (prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: metadataRefreshTask)) ==
          true) {
        registered.add(metadataRefreshTask);
      }
      return registered;
    } catch (e) {
      _logger.severe('Get registered tasks', e);
      return [];
    }
  }

  static Future<bool> isRegistered() async {
    // Legacy/global check retained for backward compatibility
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool legacy = prefs.getBool(_bgTasksRegisteredKey) ?? false;
      if (legacy) return true;
      final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
      if (activePubkey == null || activePubkey.isEmpty) return false;
      return prefs.getBool('$_bgTasksRegisteredKey:$activePubkey') ?? false;
    } catch (e) {
      _logger.warning('Read bg tasks registered flag', e);
      return false;
    }
  }

  static Future<bool> isRegisteredForActiveAccount() async {
    try {
      final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
      if (activePubkey == null || activePubkey.isEmpty) return false;
      final prefs = await SharedPreferences.getInstance();
      final bool messages =
          prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: messagesSyncTask)) ??
          false;
      final bool invites =
          prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: invitesSyncTask)) ??
          false;
      final bool metadata =
          prefs.getBool(_taskFlagKey(activePubkey: activePubkey, taskName: metadataRefreshTask)) ??
          false;
      return messages && invites && metadata;
    } catch (e) {
      _logger.warning('Read per-account bg tasks registered flag', e);
      return false;
    }
  }

  static Future<void> ensureRegistered({Duration maxAge = const Duration(hours: 6)}) async {
    try {
      final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
      if (activePubkey == null || activePubkey.isEmpty) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? lastTs = prefs.getInt('$_lastRegisteredPrefix:$activePubkey');
      final bool allFlags = await isRegisteredForActiveAccount();
      final bool stale =
          lastTs == null
              ? true
              : DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastTs)) > maxAge;
      if (!allFlags || stale) {
        await registerAllTasks();
      }
    } catch (e) {
      _logger.warning('Ensure background tasks registered', e);
    }
  }

  static Future<void> _setTaskFlag({
    required String activePubkey,
    required String taskName,
    required bool value,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taskFlagKey(activePubkey: activePubkey, taskName: taskName), value);
  }

  static String _taskFlagKey({required String activePubkey, required String taskName}) {
    return '$_taskFlagPrefix:$activePubkey:$taskName';
  }

  static List<ChatMessage> _filterNewMessages(
    List<ChatMessage> messages,
    String currentUserPubkey,
    DateTime? lastSyncTime,
    DateTime? lastReadTime,
  ) {
    final now = DateTime.now();
    final bufferCutoff = now.subtract(_messageFilterBufferSeconds);

    // Use the earliest cutoff between lastSyncTime and lastReadTime to avoid
    // missing messages that were published between these two times.
    // If neither exists, only show very recent messages (1 hour) for new groups
    DateTime? effectiveCutoff;
    if (lastSyncTime != null && lastReadTime != null) {
      effectiveCutoff = lastSyncTime.isBefore(lastReadTime) ? lastSyncTime : lastReadTime;
    } else {
      effectiveCutoff = lastSyncTime ?? lastReadTime;
    }
    final cutoffTime = effectiveCutoff ?? now.subtract(const Duration(hours: 1));

    return messages.where((message) {
      if (message.pubkey == currentUserPubkey) return false;
      if (message.isDeleted) return false;
      if (message.createdAt.isBefore(cutoffTime)) return false;
      if (message.createdAt.isAfter(bufferCutoff)) return false;
      return true;
    }).toList();
  }

  static Future<String> _getGroupDisplayName(String groupId, String activePubkey) async {
    try {
      final groups = await activeGroups(pubkey: activePubkey);
      final group = groups.firstWhere((g) => g.mlsGroupId == groupId);

      final isDM = await group.isDirectMessageType(accountPubkey: activePubkey);

      if (isDM) {
        final members = await groupMembers(pubkey: activePubkey, groupId: groupId);
        if (members.isNotEmpty) {
          final otherMemberPubkey = members.firstWhere(
            (memberPubkey) => memberPubkey != activePubkey,
            orElse: () => members.first,
          );
          try {
            final metadata = await userMetadata(pubkey: otherMemberPubkey);
            if (metadata.displayName?.isNotEmpty == true) {
              return metadata.displayName!;
            }
          } catch (e) {
            _logger.warning('Get user metadata for $otherMemberPubkey', e);
          }
          return otherMemberPubkey.substring(0, _pubkeyDisplayLength);
        }
        return _notificationTitleDirectMessage;
      } else {
        return group.name.isNotEmpty ? group.name : _notificationTitleUnknownGroup;
      }
    } catch (e) {
      _logger.warning('Get group name for $groupId', e);
      return _notificationTitleGroupChat;
    }
  }

  static Future<void> triggerTask(String taskName) async {
    try {
      _logger.info('Manually triggering task: $taskName');

      await Workmanager().registerOneOffTask(
        taskName,
        taskName,
        initialDelay: _taskDelaySeconds,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      _logger.info('Task $taskName scheduled for background execution');
    } catch (e) {
      _logger.severe('Trigger task $taskName', e);
    }
  }

  /// Gets the last sync time for a specific group from SharedPreferences
  static Future<DateTime?> _getLastSyncTime(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('bg_sync_last_$groupId');
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      _logger.warning('Get last sync time for group $groupId', e);
      return null;
    }
  }

  /// Sets the last sync time for a specific group in SharedPreferences
  static Future<void> _setLastSyncTime(String groupId, DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bg_sync_last_$groupId', time.millisecondsSinceEpoch);
    } catch (e) {
      _logger.warning('Set last sync time for group $groupId', e);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger('BackgroundTaskDispatcher');

    try {
      logger.info('Executing background task: $task');

      await RustLib.init();

      // Initialize notification service for background tasks
      try {
        await NotificationService.initialize();
        logger.info('NotificationService initialized in background task');
      } catch (e) {
        logger.warning('Failed to initialize NotificationService in background task: $e');
      }

      switch (task) {
        case BackgroundSyncService.messagesSyncTask:
          return await _handleMessagesSync();
        case BackgroundSyncService.invitesSyncTask:
          return await _handleInvitesSync();
        case BackgroundSyncService.metadataRefreshTask:
          return await _handleMetadataRefresh();
        default:
          logger.warning('Unknown background task: $task');
          return Future.value(false);
      }
    } catch (e, stackTrace) {
      logger.severe('Background task $task failed', e, stackTrace);
      return Future.value(false);
    }
  });
}

Future<bool> _handleMessagesSync() async {
  final logger = Logger('MessagesSyncTask');

  try {
    logger.info('Starting messages sync background task');

    final activePubkey = await AccountSecureStorageService.getActivePubkey();
    if (activePubkey == null) {
      logger.info('No active account found, skipping messages sync');
      return true;
    }

    final groups = await activeGroups(pubkey: activePubkey);
    if (groups.isEmpty) {
      logger.info('No groups found, skipping messages sync');
      return true;
    }

    int totalNewMessages = 0;

    for (final group in groups) {
      try {
        final lastSyncTime = await BackgroundSyncService._getLastSyncTime(group.mlsGroupId);

        final aggregatedMessages = await fetchAggregatedMessagesForGroup(
          pubkey: activePubkey,
          groupId: group.mlsGroupId,
        );

        final lastReadTime = await LastReadService.getLastRead(groupId: group.mlsGroupId);

        final newMessages = BackgroundSyncService._filterNewMessages(
          aggregatedMessages,
          activePubkey,
          lastSyncTime,
          lastReadTime,
        );

        logger.info(
          'Messages sync: Group ${group.mlsGroupId} - Found ${aggregatedMessages.length} total messages, ${newMessages.length} unread messages',
        );

        if (newMessages.isNotEmpty) {
          final groupDisplayName = await BackgroundSyncService._getGroupDisplayName(
            group.mlsGroupId,
            activePubkey,
          );

          for (final message in newMessages) {
            try {
              await NotificationService.showMessageNotification(
                id: await NotificationIdService.getIdFor(
                  key:
                      '${BackgroundSyncService._notificationTypeNewMessage}:${group.mlsGroupId}:${message.id}',
                ),
                title: groupDisplayName,
                body: message.content,
                payload: jsonEncode({
                  'type': BackgroundSyncService._notificationTypeNewMessage,
                  'groupId': group.mlsGroupId,
                  'messageId': message.id,
                  'sender': message.pubkey,
                }),
              );

              totalNewMessages++;
            } catch (e) {
              logger.warning('Show notification for message ${message.id}: $e');
            }
          }

          final latestProcessed = newMessages
              .map((m) => m.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          await BackgroundSyncService._setLastSyncTime(group.mlsGroupId, latestProcessed);
        } else {
          final now = DateTime.now();
          final bufferCutoff = now.subtract(BackgroundSyncService._messageFilterBufferSeconds);
          if (lastSyncTime == null || lastSyncTime.isBefore(bufferCutoff)) {
            await BackgroundSyncService._setLastSyncTime(group.mlsGroupId, bufferCutoff);
          }
        }
      } catch (e) {
        logger.warning('Fetch messages for group ${group.mlsGroupId}: $e');
      }
    }

    if (totalNewMessages > 0) {
      logger.info(
        'Messages sync completed successfully: Found $totalNewMessages new messages and sent notifications',
      );
    } else {
      logger.info('Messages sync completed successfully: No new messages found');
    }
    return true;
  } catch (e, stackTrace) {
    logger.severe('Messages sync task failed', e, stackTrace);
    return false;
  }
}

Future<bool> _handleInvitesSync() async {
  final logger = Logger('InvitesSyncTask');

  try {
    logger.info('Starting invites sync background task');

    final activePubkey = await AccountSecureStorageService.getActivePubkey();
    if (activePubkey == null) {
      logger.info('No active account found, skipping invites sync');
      return true;
    }

    final lastReadTime = await LastReadService.getLastRead(groupId: 'invites');
    final now = DateTime.now();
    final bufferCutoff = now.subtract(BackgroundSyncService._messageFilterBufferSeconds);
    final cutoffTime = lastReadTime ?? now.subtract(const Duration(hours: 1));

    final welcomes = await pendingWelcomes(pubkey: activePubkey);
    final newWelcomes =
        welcomes.where((w) {
          if (w.state != WelcomeState.pending) return false;
          final welcomeTime = DateTime.fromMillisecondsSinceEpoch(w.createdAt.toInt() * 1000);
          if (welcomeTime.isBefore(cutoffTime)) return false;
          if (welcomeTime.isAfter(bufferCutoff)) return false;
          return true;
        }).toList();

    logger.info(
      'Invites sync: Found ${welcomes.length} total pending welcomes, ${newWelcomes.length} new welcomes',
    );

    for (final welcome in newWelcomes) {
      try {
        await NotificationService.showMessageNotification(
          id: await NotificationIdService.getIdFor(
            key: '${BackgroundSyncService._notificationTypeInvitesSync}:${welcome.id}',
          ),
          title: BackgroundSyncService._notificationTitleNewInvitations,
          body: 'New group invitation',
          payload: jsonEncode({
            'type': BackgroundSyncService._notificationTypeInvitesSync,
            'welcomeId': welcome.id,
          }),
        );
      } catch (e) {
        logger.warning('Show notification for welcome ${welcome.id}: $e');
      }
    }

    if (newWelcomes.isNotEmpty) {
      logger.info(
        'Invites sync completed successfully: Found ${newWelcomes.length} new invites and sent notifications',
      );
    } else {
      logger.info('Invites sync completed successfully: No new invites found');
    }
    return true;
  } catch (e, stackTrace) {
    logger.severe('Invites sync task failed', e, stackTrace);
    return false;
  }
}

Future<bool> _handleMetadataRefresh() async {
  final logger = Logger('MetadataRefreshTask');

  try {
    logger.info('Starting metadata refresh background task');

    final activePubkey = await AccountSecureStorageService.getActivePubkey();
    if (activePubkey == null) {
      logger.info('No active account found, skipping metadata refresh');
      return true;
    }

    final groups = await activeGroups(pubkey: activePubkey);
    int refreshedCount = 0;

    for (final group in groups) {
      try {
        final memberPubkeys = await groupMembers(
          pubkey: activePubkey,
          groupId: group.mlsGroupId,
        );

        for (final memberPubkey in memberPubkeys) {
          try {
            await userMetadata(pubkey: memberPubkey);
            refreshedCount++;
          } catch (e) {
            logger.warning('Refresh metadata for $memberPubkey: $e');
          }
        }
      } catch (e) {
        logger.warning('Get members for group ${group.mlsGroupId}: $e');
      }
    }

    logger.info('Metadata refresh completed. Refreshed $refreshedCount user profiles');
    return true;
  } catch (e, stackTrace) {
    logger.severe('Metadata refresh task failed', e, stackTrace);
    return false;
  }
}
