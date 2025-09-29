import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
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
      _logger.severe('Failed to initialize BackgroundSyncService: $e');
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
      _logger.severe('Failed to register background tasks: $e');
      rethrow;
    }
  }

  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All background tasks cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel background tasks: $e');
    }
  }

  static Future<List<String>> getRegisteredTasks() async {
    try {
      return [messagesSyncTask, invitesSyncTask, metadataRefreshTask];
    } catch (e) {
      _logger.severe('Failed to get registered tasks: $e');
      return [];
    }
  }

  static Future<void> triggerTask(String taskName) async {
    try {
      await Workmanager().registerOneOffTask(
        'manual_$taskName',
        taskName,
        initialDelay: const Duration(seconds: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      _logger.info('Manually triggered task: $taskName');
    } catch (e) {
      _logger.severe('Failed to trigger task $taskName: $e');
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

    int newMessagesCount = 0;

    for (final group in groups) {
      try {
        final aggregatedMessages = await fetchAggregatedMessagesForGroup(
          pubkey: activePubkey,
          groupId: group.mlsGroupId,
        );

        newMessagesCount += aggregatedMessages.length;
        logger.fine('Found ${aggregatedMessages.length} messages in group ${group.mlsGroupId}');
      } catch (e) {
        logger.warning('Failed to fetch messages for group ${group.mlsGroupId}: $e');
      }
    }

    if (newMessagesCount > 0) {
      await NotificationService.showMessageNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'New Messages',
        body: '$newMessagesCount new messages received',
        payload: jsonEncode({'type': 'messages_sync', 'count': newMessagesCount}),
      );
    }

    logger.info('Messages sync completed. Found $newMessagesCount messages');
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
        title: 'New Invitations',
        body: '${newWelcomes.length} new group invitation${newWelcomes.length > 1 ? 's' : ''}',
        payload: jsonEncode({'type': 'invites_sync', 'count': newWelcomes.length}),
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
            logger.warning('Failed to refresh metadata for $memberPubkey: $e');
          }
        }
      } catch (e) {
        logger.warning('Failed to get members for group ${group.mlsGroupId}: $e');
      }
    }

    logger.info('Metadata refresh completed. Refreshed $refreshedCount user profiles');
    return true;
  } catch (e, stackTrace) {
    logger.severe('Metadata refresh task failed', e, stackTrace);
    return false;
  }
}
