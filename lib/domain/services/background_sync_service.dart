import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';
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

  static const Duration _messagesSyncFrequency = Duration(minutes: 5);
  static const Duration _invitesSyncFrequency = Duration(minutes: 5);
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
      _logger.severe('Background tasks registration', e);
      rethrow;
    }
  }

  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All background tasks cancelled');
    } catch (e) {
      _logger.severe('Background tasks cancellation', e);
    }
  }

  static Future<List<String>> getRegisteredTasks() async {
    try {
      return [messagesSyncTask, invitesSyncTask, metadataRefreshTask];
    } catch (e) {
      _logger.severe('Get registered tasks', e);
      return [];
    }
  }

  static List<ChatMessage> _filterNewMessages(
    List<ChatMessage> messages,
    String currentUserPubkey,
    DateTime? lastReadTime,
  ) {
    final now = DateTime.now();
    final bufferCutoff = now.subtract(_messageFilterBufferSeconds);

    // If no last read time, only show very recent messages (1 hour) for new groups
    final cutoffTime = lastReadTime ?? now.subtract(const Duration(hours: 1));

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
        final lastReadTime = await LastReadService.getLastRead(groupId: group.mlsGroupId);

        final aggregatedMessages = await fetchAggregatedMessagesForGroup(
          pubkey: activePubkey,
          groupId: group.mlsGroupId,
        );

        final newMessages = BackgroundSyncService._filterNewMessages(
          aggregatedMessages,
          activePubkey,
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
                id:
                    Object.hash(
                      BackgroundSyncService._notificationTypeNewMessage,
                      message.id,
                    ) &
                    0x7fffffff,
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
    final cutoffTime = lastReadTime ?? now.subtract(const Duration(hours: 12));

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
          id:
              Object.hash(
                BackgroundSyncService._notificationTypeInvitesSync,
                welcome.id,
              ) &
              0x7fffffff,
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
