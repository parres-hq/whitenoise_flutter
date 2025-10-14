import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/background_task_config.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncService {
  static final _logger = Logger('BackgroundSyncService');

  static const BackgroundTaskConfig metadataRefreshTask = BackgroundTaskConfig(
    id: 'com.whitenoise.metadata_refresh',
    uniqueName: 'metadata_refresh',
    displayName: 'Metadata Refresh',
    frequency: Duration(hours: 12),
  );

  static const List<BackgroundTaskConfig> allTasks = [
    metadataRefreshTask,
  ];

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.fine('BackgroundSyncService already initialized');
      return;
    }
    try {
      await _initWorkManager();
      _isInitialized = true;
      _logger.info('BackgroundSyncService initialized successfully');
    } catch (e) {
      _logger.severe('BackgroundSyncService initialization', e);
    }
  }

  static Future<void> _initWorkManager() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
    } catch (e) {
      _logger.severe('BackgroundSyncService _initWorkManager', e);
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger('BackgroundTaskDispatcher');

    try {
      logger.info('Executing background task: $task');

      try {
        await RustLib.init();
        logger.info('RustLib initialized in background task');
      } catch (e) {
        logger.warning('Failed to initialize RustLib in background task: $e');
      }

      return _handleMetadataRefresh();
    } catch (e, stackTrace) {
      logger.severe('Background task $task failed', e, stackTrace);
      return Future.value(false);
    }
  });
}
