import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
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
  static const Duration _defaultSyncCutoffHours = Duration(hours: 24);
  static const Duration _messageFilterBufferSeconds = Duration(seconds: 1);
  static const Duration _taskDelaySeconds = Duration(seconds: 1);

  // Display name constants
  static const int _pubkeyDisplayLength = 8;

  static bool _isInitialized = false;

  // Helper methods for error handling
  static void _logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (stackTrace != null) {
      _logger.severe('$context failed', error, stackTrace);
    } else {
      _logger.severe('$context failed: $error');
    }
  }

  static void _logWarning(String context, dynamic error) {
    _logger.warning('$context: $error');
  }

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
      _logError('BackgroundSyncService initialization', e);
      rethrow;
    }
  }

  static Future<void> registerAllTasks() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Workmanager().registerPeriodicTask(
        'messages_sync',
        messagesSyncTask,
        frequency: _messagesSyncFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      await Workmanager().registerPeriodicTask(
        'invites_sync',
        invitesSyncTask,
        frequency: _invitesSyncFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      await Workmanager().registerPeriodicTask(
        'metadata_refresh',
        metadataRefreshTask,
        frequency: _metadataRefreshFrequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      _logger.info('All background tasks registered successfully');
    } catch (e) {
      _logError('Background tasks registration', e);
      rethrow;
    }
  }

  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All background tasks cancelled');
    } catch (e) {
      _logError('Background tasks cancellation', e);
    }
  }

  static Future<List<String>> getRegisteredTasks() async {
    try {
      return [messagesSyncTask, invitesSyncTask, metadataRefreshTask];
    } catch (e) {
      _logError('Get registered tasks', e);
      return [];
    }
  }

  static Future<DateTime?> _getLastGroupSyncTime(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('background_sync_group_$groupId');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      _logWarning('Get last sync time for group $groupId', e);
    }
    return null;
  }

  static Future<void> _setLastGroupSyncTime(String groupId, DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('background_sync_group_$groupId', time.millisecondsSinceEpoch);
    } catch (e) {
      _logWarning('Set last sync time for group $groupId', e);
    }
  }

  static List<ChatMessage> _filterNewMessages(
    List<ChatMessage> messages,
    String currentUserPubkey,
    DateTime? lastSyncTime,
  ) {
    final now = DateTime.now();
    final cutoffTime = lastSyncTime ?? now.subtract(_defaultSyncCutoffHours);

    return messages.where((message) {
      if (message.pubkey == currentUserPubkey) return false;
      if (message.isDeleted) return false;
      if (message.createdAt.isBefore(cutoffTime)) return false;
      if (message.createdAt.isAfter(now.subtract(_messageFilterBufferSeconds))) return false;
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
            _logWarning('Get user metadata for $otherMemberPubkey', e);
          }
          return otherMemberPubkey.substring(0, _pubkeyDisplayLength);
        }
        return _notificationTitleDirectMessage;
      } else {
        return group.name.isNotEmpty ? group.name : _notificationTitleUnknownGroup;
      }
    } catch (e) {
      _logWarning('Get group name for $groupId', e);
      return _notificationTitleGroupChat;
    }
  }

  static Future<void> triggerTask(String taskName) async {
    try {
      _logger.info('Manually triggering task: $taskName');

      switch (taskName) {
        case messagesSyncTask:
          await _handleMessagesSync();
          break;
        case invitesSyncTask:
          await _handleInvitesSync();
          break;
        case metadataRefreshTask:
          await _handleMetadataRefresh();
          break;
        default:
          _logger.warning('Unknown task for immediate execution: $taskName');
          return;
      }

      await Workmanager().registerOneOffTask(
        taskName,
        taskName,
        initialDelay: _taskDelaySeconds,
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      _logger.info('Task $taskName executed immediately and scheduled for background execution');
    } catch (e) {
      _logError('Trigger task $taskName', e);
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

    final accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping messages sync');
      return true;
    }

    final activeAccount = accounts.first;
    final activePubkey = activeAccount.pubkey;

    final groups = await activeGroups(pubkey: activePubkey);
    if (groups.isEmpty) {
      logger.info('No groups found, skipping messages sync');
      return true;
    }

    int totalNewMessages = 0;
    final syncTime = DateTime.now();

    for (final group in groups) {
      try {
        final lastSyncTime = await BackgroundSyncService._getLastGroupSyncTime(group.mlsGroupId);

        final aggregatedMessages = await fetchAggregatedMessagesForGroup(
          pubkey: activePubkey,
          groupId: group.mlsGroupId,
        );

        final newMessages = BackgroundSyncService._filterNewMessages(
          aggregatedMessages,
          activePubkey,
          lastSyncTime,
        );

        logger.info(
          'Messages sync: Group ${group.mlsGroupId} - Found ${aggregatedMessages.length} total messages, ${newMessages.length} new messages',
        );

        if (newMessages.isNotEmpty) {
          final groupDisplayName = await BackgroundSyncService._getGroupDisplayName(
            group.mlsGroupId,
            activePubkey,
          );

          for (final message in newMessages) {
            try {
              await NotificationService.showMessageNotification(
                id: message.id.hashCode,
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
        }

        await BackgroundSyncService._setLastGroupSyncTime(group.mlsGroupId, syncTime);
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

    final accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping invites sync');
      return true;
    }

    final activeAccount = accounts.first;
    final activePubkey = activeAccount.pubkey;

    final welcomes = await pendingWelcomes(pubkey: activePubkey);
    final newWelcomes = welcomes.where((w) => w.state == WelcomeState.pending).toList();

    if (newWelcomes.isNotEmpty) {
      await NotificationService.showMessageNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title: BackgroundSyncService._notificationTitleNewInvitations,
        body: '${newWelcomes.length} new group invitation${newWelcomes.length > 1 ? 's' : ''}',
        payload: jsonEncode({
          'type': BackgroundSyncService._notificationTypeInvitesSync,
          'count': newWelcomes.length,
        }),
      );
    }

    logger.info('Invites sync completed. Found ${newWelcomes.length} new invites');
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

    final accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping metadata refresh');
      return true;
    }

    final activeAccount = accounts.first;
    final activePubkey = activeAccount.pubkey;

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
