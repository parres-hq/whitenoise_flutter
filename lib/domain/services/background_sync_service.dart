import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/background_task_config.dart';
import 'package:whitenoise/domain/services/background_sync_handler.dart';
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

  static bool _isWorkManagerInitialized = false;
  static bool _isForegroundTaskInitialized = false;

  static Future<void> initialize() async {
    try {
      initForegroundTask();
      await initWorkManager();
      _logger.info('initialized successfully');
    } catch (e) {
      _logger.severe('initialize', e);
    }
  }

  static Future<void> initWorkManager() async {
    if (_isWorkManagerInitialized) {
      _logger.fine('workmanager already initialized');
      return;
    }
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      _isWorkManagerInitialized = true;
      _logger.info('workmanager initialized successfully');
    } catch (e) {
      _logger.severe('_initWorkManager', e);
    }
  }

  static void initForegroundTask() {
    if (_isForegroundTaskInitialized) {
      _logger.fine('Foreground task already initialized');
      return;
    }
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'foreground_service',
          channelName: 'Foreground Service Notification',
          channelDescription: 'This notification appears when the foreground service is running.',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          /// Current: 60 seconds - Polling-based sync
          ///
          /// Future with streams (recommended: 15 minutes):
          /// - Real-time messages delivered via WebSocket/SSE streams
          /// - Background task only checks stream health and reconnects if needed
          /// - Significant battery savings: 15 wakeups/hour → 4 wakeups/hour
          /// - Instant notifications via streams instead of polling
          ///
          /// Current interval chosen as compromise:
          /// - 60s provides reasonably timely notifications (~1 min delay)
          /// - Will increase to 900000ms (15 min) when streams are implemented
          eventAction: ForegroundTaskEventAction.repeat(60000),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWifiLock: true,
        ),
      );
      _isForegroundTaskInitialized = true;
      _logger.info('Foreground task initialized successfully');
    } catch (e) {
      _logger.severe('BackgroundSyncService _initForegroundTask', e);
    }
  }

  static Future<void> startForegroundTask() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceTypes: [
            ForegroundServiceTypes.dataSync,
            ForegroundServiceTypes.remoteMessaging,
          ],
          serviceId: 303,
          notificationTitle: 'Background Service',
          notificationText: 'Tap to return to the app',
          notificationInitialRoute: '/',
          callback: startCallback,
        );
      }
    } catch (e) {
      _logger.severe('BackgroundSyncService startForegroundTask', e);
    }
  }

  static Future<void> registerMetadataSyncTask() async {
    _logger.info('Metadata refresh task  registering');
    if (!_isWorkManagerInitialized) {
      _logger.info('Metadata refresh task  !registering');

      await initWorkManager();
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
