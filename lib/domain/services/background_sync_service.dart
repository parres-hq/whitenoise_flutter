import 'dart:async';

import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
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

  static const Duration _messagesSyncFrequency = Duration(minutes: 15);
  static const Duration _invitesSyncFrequency = Duration(minutes: 15);
  static const Duration _metadataRefreshFrequency = Duration(hours: 24);
  static const Duration _taskDelaySeconds = Duration(seconds: 1);

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

  static Future<void> registerNotificationTasks() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      try {
        await Workmanager().registerPeriodicTask(
          'messages_sync',
          messagesSyncTask,
          frequency: _messagesSyncFrequency,
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
        _logger.info('Messages sync task registered successfully');
      } catch (e) {
        _logger.severe('Register messages sync task', e);
        rethrow;
      }

      try {
        await Workmanager().registerPeriodicTask(
          'invites_sync',
          invitesSyncTask,
          frequency: _invitesSyncFrequency,
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
        _logger.info('Invites sync task registered successfully');
      } catch (e) {
        _logger.severe('Register invites sync task', e);
        rethrow;
      }

      _logger.info('Notification tasks registered successfully');
    } catch (e) {
      _logger.severe('Notification tasks registration', e);
      rethrow;
    }
  }

  static Future<void> registerMetadataSyncTask() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Workmanager().registerPeriodicTask(
        'metadata_refresh',
        metadataRefreshTask,
        frequency: _metadataRefreshFrequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.info('Metadata refresh task registered successfully');
    } catch (e) {
      _logger.severe('Register metadata refresh task', e);
      rethrow;
    }
  }

  static Future<void> registerAllTasks() async {
    await registerNotificationTasks();
    await registerMetadataSyncTask();
  }

  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All background tasks cancelled');
    } catch (e) {
      _logger.severe('Background tasks cancellation', e);
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
    final String? activePubkey = await AccountSecureStorageService.getActivePubkey();
    if (activePubkey == null) {
      logger.info('No active account found, skipping messages sync');
      return true;
    }
    final List<dynamic> groups = await activeGroups(pubkey: activePubkey);
    if (groups.isEmpty) {
      logger.info('No groups found, skipping messages sync');
      return true;
    }
    int totalNewMessages = 0;
    for (final group in groups) {
      try {
        final int newCount = await _syncMessagesForGroup(
          groupId: group.mlsGroupId,
          activePubkey: activePubkey,
          logger: logger,
        );
        totalNewMessages += newCount;
      } catch (e) {
        logger.warning('Sync group ${group.mlsGroupId}: $e');
      }
    }
    logger.info(
      totalNewMessages > 0
          ? 'Messages sync completed: $totalNewMessages new messages notified'
          : 'Messages sync completed: No new messages',
    );
    return true;
  } catch (e, stackTrace) {
    logger.severe('Messages sync task failed', e, stackTrace);
    return false;
  }
}

Future<int> _syncMessagesForGroup({
  required String groupId,
  required String activePubkey,
  required Logger logger,
}) async {
  final DateTime? lastSyncTime = await MessageSyncService.getLastSyncTime(
    activePubkey: activePubkey,
    groupId: groupId,
  );
  final List<ChatMessage> aggregatedMessages = await fetchAggregatedMessagesForGroup(
    pubkey: activePubkey,
    groupId: groupId,
  );
  final List<ChatMessage> newMessages = await MessageSyncService.filterNewMessages(
    aggregatedMessages,
    activePubkey,
    groupId,
    lastSyncTime,
  );
  logger.info(
    'Messages sync: Group $groupId - Found ${aggregatedMessages.length} total messages, ${newMessages.length} unread messages',
  );
  if (newMessages.isEmpty) {
    await _updateCheckpointNoNewMessages(
      activePubkey: activePubkey,
      groupId: groupId,
      lastSyncTime: lastSyncTime,
    );
    return 0;
  }
  await MessageSyncService.notifyNewMessages(
    groupId: groupId,
    activePubkey: activePubkey,
    newMessages: newMessages,
  );
  await _updateCheckpointWithNewMessages(
    activePubkey: activePubkey,
    groupId: groupId,
    newMessages: newMessages,
  );
  return newMessages.length;
}

Future<void> _updateCheckpointNoNewMessages({
  required String activePubkey,
  required String groupId,
  required DateTime? lastSyncTime,
}) async {
  final DateTime now = DateTime.now();
  final DateTime earliestAllowedTime = now.subtract(
    const Duration(seconds: 1),
  );
  if (lastSyncTime == null || lastSyncTime.isBefore(earliestAllowedTime)) {
    await MessageSyncService.setLastSyncTime(
      activePubkey: activePubkey,
      groupId: groupId,
      time: earliestAllowedTime,
    );
  }
}

Future<void> _updateCheckpointWithNewMessages({
  required String activePubkey,
  required String groupId,
  required List<ChatMessage> newMessages,
}) async {
  final DateTime latestProcessed = newMessages
      .map((m) => m.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  await MessageSyncService.setLastSyncTime(
    activePubkey: activePubkey,
    groupId: groupId,
    time: latestProcessed,
  );
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

    // Use checkpoint tracking for invites like we do for messages
    final DateTime? lastSyncTime = await MessageSyncService.getLastSyncTime(
      activePubkey: activePubkey,
      groupId: 'invites',
    );
    final now = DateTime.now();
    final earliestAllowedTime = now.subtract(const Duration(seconds: 1));
    final lastProcessedTime = lastSyncTime ?? now.subtract(const Duration(hours: 1));

    final welcomes = await pendingWelcomes(pubkey: activePubkey);
    final newWelcomes =
        welcomes.where((w) {
          final welcomeTime = DateTime.fromMillisecondsSinceEpoch(w.createdAt.toInt() * 1000);
          if (!welcomeTime.isAfter(lastProcessedTime)) return false;
          if (welcomeTime.isAfter(earliestAllowedTime)) return false;
          return true;
        }).toList();

    logger.info(
      'Invites sync: Found ${welcomes.length} total pending welcomes, ${newWelcomes.length} new welcomes',
    );

    await MessageSyncService.notifyNewInvites(
      newWelcomes: newWelcomes,
    );

    // Update checkpoint after processing
    if (newWelcomes.isEmpty) {
      if (lastSyncTime == null || lastSyncTime.isBefore(earliestAllowedTime)) {
        await MessageSyncService.setLastSyncTime(
          activePubkey: activePubkey,
          groupId: 'invites',
          time: earliestAllowedTime,
        );
      }
    } else {
      final DateTime latestWelcome = newWelcomes
          .map((w) => DateTime.fromMillisecondsSinceEpoch(w.createdAt.toInt() * 1000))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      await MessageSyncService.setLastSyncTime(
        activePubkey: activePubkey,
        groupId: 'invites',
        time: latestWelcome,
      );
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
