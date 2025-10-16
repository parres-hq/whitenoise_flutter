import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/notification_service.dart';

class BackgroundSyncHandler extends TaskHandler {
  final _log = Logger('BackgroundSyncHandler');
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await NotificationService.initialize();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      _log.fine('Foreground task onRepeatEvent at $timestamp');

      // Testing: Send random greeting notification
      await NotificationService.sendRandomGreetingNotification();

      // Perform your background sync operations here.
      // For example, you might want to call your sync service:
      // await SyncService.performSync();
      _log.fine('Background sync operations completed at $timestamp');
    } catch (e, stackTrace) {
      _log.severe('Error in onRepeatEvent: $e', e, stackTrace);
    }
    // Send data to main isolate.
    FlutterForegroundTask.sendDataToMain(timestamp.millisecondsSinceEpoch);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _log.info('Foreground task destroyed at $timestamp, isTimeout: $isTimeout');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundSyncHandler());
}
