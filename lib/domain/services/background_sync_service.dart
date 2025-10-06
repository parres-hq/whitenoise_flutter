import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/background_task_config.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
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

  static const BackgroundTaskConfig messagesSyncTask = BackgroundTaskConfig(
    id: 'com.whitenoise.messages_sync',
    uniqueName: 'messages_sync',
    displayName: 'Messages Sync',
    frequency: Duration(minutes: 15),
  );

  static const BackgroundTaskConfig invitesSyncTask = BackgroundTaskConfig(
    id: 'com.whitenoise.invites_sync',
    uniqueName: 'invites_sync',
    displayName: 'Invites Sync',
    frequency: Duration(minutes: 15),
  );

  static const BackgroundTaskConfig metadataRefreshTask = BackgroundTaskConfig(
    id: 'com.whitenoise.metadata_refresh',
    uniqueName: 'metadata_refresh',
    displayName: 'Metadata Refresh',
    frequency: Duration(hours: 24),
  );

  static const List<BackgroundTaskConfig> allTasks = [
    messagesSyncTask,
    invitesSyncTask,
    metadataRefreshTask,
  ];

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
    }
  }

  static Future<void> registerNotificationTasks() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await registerMessagesSyncTask();
      await registerInvitesSyncTask();
    } catch (e) {
      _logger.severe('Notification tasks registration', e);
    }
  }

  static Future<void> registerMessagesSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        messagesSyncTask.uniqueName,
        messagesSyncTask.id,
        frequency: messagesSyncTask.frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.info('Messages sync task registered successfully');
    } catch (e) {
      _logger.severe('Register messages sync task', e);
    }
  }

  static Future<void> registerInvitesSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        invitesSyncTask.uniqueName,
        invitesSyncTask.id,
        frequency: invitesSyncTask.frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.info('Invites sync task registered successfully');
    } catch (e) {
      _logger.severe('Register invites sync task', e);
    }
  }

  static Future<void> registerMetadataSyncTask() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await Workmanager().registerPeriodicTask(
        metadataRefreshTask.uniqueName,
        metadataRefreshTask.id,
        frequency: metadataRefreshTask.frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.info('Metadata refresh task registered successfully');
    } catch (e) {
      _logger.severe('Register metadata refresh task', e);
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

  static Future<bool> isTaskScheduled(String taskName) async {
    try {
      if (Platform.isAndroid) {
        final isScheduled = await Workmanager().isScheduledByUniqueName(taskName);
        _logger.info('Task $taskName is scheduled: $isScheduled');
        return isScheduled;
      } else if (Platform.isIOS) {
        //? This is a workaround to check if the task is scheduled on iOS
        //? Because the isScheduledByUniqueName method is not available on iOS
        //? We need to print the scheduled tasks and check if the task is in the list
        //? this is not so reliable
        final scheduledTasks = await Workmanager().printScheduledTasks();
        final isScheduled = scheduledTasks.contains(taskName);
        _logger.info('Task $taskName is scheduled: $isScheduled');
        return isScheduled;
      }
      return false;
    } catch (e) {
      _logger.severe('Check if task is registered', e);
      return false;
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

      if (task == BackgroundSyncService.messagesSyncTask.id) {
        return await _handleMessagesSync();
      } else if (task == BackgroundSyncService.invitesSyncTask.id) {
        return await _handleInvitesSync();
      } else if (task == BackgroundSyncService.metadataRefreshTask.id) {
        return await _handleMetadataRefresh();
      } else {
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
    final List<Account> accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping messages sync');
      return true;
    }
    logger.info('Found ${accounts.length} accounts to sync');
    int totalNewMessages = 0;
    for (final account in accounts) {
      final int newCount = await _syncMessagesForAccount(
        account: account,
        logger: logger,
      );
      totalNewMessages += newCount;
    }
    logger.info(
      totalNewMessages > 0
          ? 'Messages sync completed: $totalNewMessages new messages notified across ${accounts.length} accounts'
          : 'Messages sync completed: No new messages',
    );
    return true;
  } catch (e, stackTrace) {
    logger.severe('Messages sync task failed', e, stackTrace);
    return false;
  }
}

Future<int> _syncMessagesForAccount({
  required Account account,
  required Logger logger,
}) async {
  try {
    final List<dynamic> groups = await activeGroups(pubkey: account.pubkey);
    logger.info('Account ${account.pubkey}: Found ${groups.length} groups');
    int newMessagesCount = 0;
    for (final group in groups) {
      try {
        final int newCount = await _syncMessagesForGroup(
          groupId: group.mlsGroupId,
          accountPubkey: account.pubkey,
          logger: logger,
        );
        newMessagesCount += newCount;
      } catch (e) {
        logger.warning('Sync group ${group.mlsGroupId} for account ${account.pubkey}: $e');
      }
    }
    return newMessagesCount;
  } catch (e) {
    logger.warning('Sync messages for account ${account.pubkey}: $e');
    return 0;
  }
}

Future<int> _syncMessagesForGroup({
  required String groupId,
  required String accountPubkey,
  required Logger logger,
}) async {
  final DateTime? lastSyncTime = await MessageSyncService.getLastSyncTime(
    activePubkey: accountPubkey,
    groupId: groupId,
  );
  final List<ChatMessage> aggregatedMessages = await fetchAggregatedMessagesForGroup(
    pubkey: accountPubkey,
    groupId: groupId,
  );
  final List<ChatMessage> newMessages = await MessageSyncService.filterNewMessages(
    aggregatedMessages,
    accountPubkey,
    groupId,
    lastSyncTime,
  );
  logger.info(
    'Messages sync: Group $groupId - Found ${aggregatedMessages.length} total messages, ${newMessages.length} unread messages',
  );
  if (newMessages.isEmpty) {
    await _updateCheckpointNoNewMessages(
      accountPubkey: accountPubkey,
      groupId: groupId,
      lastSyncTime: lastSyncTime,
    );
    return 0;
  }
  await MessageSyncService.notifyNewMessages(
    groupId: groupId,
    activePubkey: accountPubkey,
    newMessages: newMessages,
  );
  await _updateCheckpointWithNewMessages(
    accountPubkey: accountPubkey,
    groupId: groupId,
    newMessages: newMessages,
  );
  return newMessages.length;
}

Future<void> _updateCheckpointNoNewMessages({
  required String accountPubkey,
  required String groupId,
  required DateTime? lastSyncTime,
}) async {
  final DateTime now = DateTime.now();
  final DateTime earliestAllowedTime = now.subtract(
    const Duration(seconds: 1),
  );
  if (lastSyncTime == null || lastSyncTime.isBefore(earliestAllowedTime)) {
    await MessageSyncService.setLastSyncTime(
      activePubkey: accountPubkey,
      groupId: groupId,
      time: earliestAllowedTime,
    );
  }
}

Future<void> _updateCheckpointWithNewMessages({
  required String accountPubkey,
  required String groupId,
  required List<ChatMessage> newMessages,
}) async {
  final DateTime latestProcessed = newMessages
      .map((m) => m.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  await MessageSyncService.setLastSyncTime(
    activePubkey: accountPubkey,
    groupId: groupId,
    time: latestProcessed,
  );
}

Future<bool> _handleInvitesSync() async {
  final logger = Logger('InvitesSyncTask');

  try {
    logger.info('Starting invites sync background task');

    final List<Account> accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping invites sync');
      return true;
    }

    logger.info('Found ${accounts.length} accounts to sync invites');
    int totalNewInvites = 0;

    for (final account in accounts) {
      final int newCount = await _syncInvitesForAccount(
        account: account,
        logger: logger,
      );
      totalNewInvites += newCount;
    }

    if (totalNewInvites > 0) {
      logger.info(
        'Invites sync completed: Found $totalNewInvites new invites across ${accounts.length} accounts',
      );
    } else {
      logger.info('Invites sync completed: No new invites found');
    }
    return true;
  } catch (e, stackTrace) {
    logger.severe('Invites sync task failed', e, stackTrace);
    return false;
  }
}

Future<int> _syncInvitesForAccount({
  required Account account,
  required Logger logger,
}) async {
  try {
    final DateTime? lastSyncTime = await MessageSyncService.getLastSyncTime(
      activePubkey: account.pubkey,
      groupId: 'invites',
    );
    final now = DateTime.now();
    final earliestAllowedTime = now.subtract(const Duration(seconds: 1));
    final lastProcessedTime = lastSyncTime ?? now.subtract(const Duration(hours: 1));

    final welcomes = await pendingWelcomes(pubkey: account.pubkey);
    final newWelcomes = _filterNewWelcomes(
      welcomes: welcomes,
      lastProcessedTime: lastProcessedTime,
      earliestAllowedTime: earliestAllowedTime,
    );

    logger.info(
      'Account ${account.pubkey}: Found ${welcomes.length} total pending welcomes, ${newWelcomes.length} new welcomes',
    );

    await MessageSyncService.notifyNewInvites(newWelcomes: newWelcomes);

    await _updateInviteCheckpoint(
      accountPubkey: account.pubkey,
      newWelcomes: newWelcomes,
      lastSyncTime: lastSyncTime,
      earliestAllowedTime: earliestAllowedTime,
    );

    return newWelcomes.length;
  } catch (e) {
    logger.warning('Sync invites for account ${account.pubkey}: $e');
    return 0;
  }
}

List<Welcome> _filterNewWelcomes({
  required List<Welcome> welcomes,
  required DateTime lastProcessedTime,
  required DateTime earliestAllowedTime,
}) {
  return welcomes.where((w) {
    final welcomeTime = DateTime.fromMillisecondsSinceEpoch(w.createdAt.toInt() * 1000);
    if (!welcomeTime.isAfter(lastProcessedTime)) return false;
    if (welcomeTime.isAfter(earliestAllowedTime)) return false;
    return true;
  }).toList();
}

Future<void> _updateInviteCheckpoint({
  required String accountPubkey,
  required List<Welcome> newWelcomes,
  required DateTime? lastSyncTime,
  required DateTime earliestAllowedTime,
}) async {
  if (newWelcomes.isEmpty) {
    if (lastSyncTime == null || lastSyncTime.isBefore(earliestAllowedTime)) {
      await MessageSyncService.setLastSyncTime(
        activePubkey: accountPubkey,
        groupId: 'invites',
        time: earliestAllowedTime,
      );
    }
  } else {
    final DateTime latestWelcome = newWelcomes
        .map((w) => DateTime.fromMillisecondsSinceEpoch(w.createdAt.toInt() * 1000))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    await MessageSyncService.setLastSyncTime(
      activePubkey: accountPubkey,
      groupId: 'invites',
      time: latestWelcome,
    );
  }
}

Future<bool> _handleMetadataRefresh() async {
  final logger = Logger('MetadataRefreshTask');

  try {
    logger.info('Starting metadata refresh background task');

    final List<Account> accounts = await getAccounts();
    if (accounts.isEmpty) {
      logger.info('No accounts found, skipping metadata refresh');
      return true;
    }

    logger.info('Found ${accounts.length} accounts to refresh metadata');
    int refreshedCount = 0;

    for (final account in accounts) {
      final int count = await _refreshMetadataForAccount(
        account: account,
        logger: logger,
      );
      refreshedCount += count;
    }

    logger.info(
      'Metadata refresh completed. Refreshed $refreshedCount user profiles across ${accounts.length} accounts',
    );
    return true;
  } catch (e, stackTrace) {
    logger.severe('Metadata refresh task failed', e, stackTrace);
    return false;
  }
}

Future<int> _refreshMetadataForAccount({
  required Account account,
  required Logger logger,
}) async {
  try {
    final groups = await activeGroups(pubkey: account.pubkey);
    logger.info('Account ${account.pubkey}: Found ${groups.length} groups');

    int refreshedCount = 0;
    for (final group in groups) {
      final int count = await _refreshMetadataForGroup(
        accountPubkey: account.pubkey,
        group: group,
        logger: logger,
      );
      refreshedCount += count;
    }
    return refreshedCount;
  } catch (e) {
    logger.warning('Refresh metadata for account ${account.pubkey}: $e');
    return 0;
  }
}

Future<int> _refreshMetadataForGroup({
  required String accountPubkey,
  required dynamic group,
  required Logger logger,
}) async {
  try {
    final memberPubkeys = await groupMembers(
      pubkey: accountPubkey,
      groupId: group.mlsGroupId,
    );

    int refreshedCount = 0;
    for (final memberPubkey in memberPubkeys) {
      try {
        await userMetadata(pubkey: memberPubkey);
        refreshedCount++;
      } catch (e) {
        logger.warning('Refresh metadata for $memberPubkey: $e');
      }
    }
    return refreshedCount;
  } catch (e) {
    logger.warning('Get members for group ${group.mlsGroupId}: $e');
    return 0;
  }
}
