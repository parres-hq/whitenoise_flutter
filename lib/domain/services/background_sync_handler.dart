import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage, fetchAggregatedMessagesForGroup;
import 'package:whitenoise/src/rust/api/welcomes.dart' show pendingWelcomes;
import 'package:whitenoise/src/rust/frb_generated.dart';

/// Internal class to batch messages for a single group.
class _GroupMessageBatch {
  final String groupId;
  final String accountPubkey;
  final List<ChatMessage> messages;

  _GroupMessageBatch({
    required this.groupId,
    required this.accountPubkey,
    required this.messages,
  });
}

class BackgroundSyncHandler extends TaskHandler {
  final _log = Logger('BackgroundSyncHandler');

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      await NotificationService.initialize();
      await RustLib.init();
      _log.info('BackgroundSyncHandler initialized at $timestamp');
    } catch (e, stackTrace) {
      _log.severe('Error initializing BackgroundSyncHandler: $e', e, stackTrace);
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      _log.fine('Background sync started at $timestamp');
      final messageBatch = await _collectNewMessages();
      await _sendBatchedNotifications(messageBatch);
      await _syncInvitesForAllAccounts();
      _log.fine('Background sync completed at $timestamp');
    } catch (e, stackTrace) {
      _log.severe('Error in onRepeatEvent: $e', e, stackTrace);
    }
    FlutterForegroundTask.sendDataToMain(timestamp.millisecondsSinceEpoch);
  }

  /// Collects all new messages from all accounts and groups without sending notifications.
  /// Returns a map of groupId -> list of new messages for batching.
  Future<Map<String, _GroupMessageBatch>> _collectNewMessages() async {
    final Map<String, _GroupMessageBatch> messageBatch = {};
    
    try {
      final accounts = await getAccounts();
      if (accounts.isEmpty) {
        _log.fine('No accounts found, skipping message sync');
        return messageBatch;
      }
      
      _log.fine('Collecting new messages for ${accounts.length} account(s)');
      
      for (final account in accounts) {
        try {
          await _collectMessagesForAccount(account.pubkey, messageBatch);
        } catch (e, stackTrace) {
          _log.warning('Message collection failed for ${account.pubkey}: $e', e, stackTrace);
        }
      }
      
      final totalMessages = messageBatch.values.fold(0, (sum, batch) => sum + batch.messages.length);
      _log.info('Collected $totalMessages new message(s) across ${messageBatch.length} group(s)');
      
    } catch (e, stackTrace) {
      _log.warning('Error collecting messages for all accounts: $e', e, stackTrace);
    }
    
    return messageBatch;
  }

  Future<void> _collectMessagesForAccount(
    String accountPubkey,
    Map<String, _GroupMessageBatch> messageBatch,
  ) async {
    try {
      final groups = await activeGroups(pubkey: accountPubkey);
      _log.fine('Found ${groups.length} active group(s) for account $accountPubkey');
      
      for (final group in groups) {
        await _collectMessagesForGroup(
          accountPubkey: accountPubkey,
          groupId: group.mlsGroupId,
          messageBatch: messageBatch,
        );
      }
    } catch (e, stackTrace) {
      _log.warning('Error collecting messages for account $accountPubkey: $e', e, stackTrace);
    }
  }

  Future<void> _collectMessagesForGroup({
    required String accountPubkey,
    required String groupId,
    required Map<String, _GroupMessageBatch> messageBatch,
  }) async {
    try {
      final lastSyncTime = await MessageSyncService.getLastSyncTime(
        activePubkey: accountPubkey,
        groupId: groupId,
      );
      final messages = await fetchAggregatedMessagesForGroup(
        pubkey: accountPubkey,
        groupId: groupId,
      );

      final newMessages = await MessageSyncService.filterNewMessages(
        messages,
        accountPubkey,
        groupId,
        lastSyncTime,
      );
      
      if (newMessages.isNotEmpty) {
        _log.fine('Found ${newMessages.length} new message(s) in group $groupId');
        messageBatch[groupId] = _GroupMessageBatch(
          groupId: groupId,
          accountPubkey: accountPubkey,
          messages: newMessages,
        );
      }
    } catch (e, stackTrace) {
      _log.warning('Error collecting messages for group $groupId: $e', e, stackTrace);
    }
  }

  /// Sends notifications based on the collected message batch.
  /// Uses smart batching to prevent notification spam:
  /// - 1-3 messages per group: Individual notifications
  /// - 4+ messages per group: Summary notification for that group
  /// - 10+ total messages: Single summary notification for all
  Future<void> _sendBatchedNotifications(Map<String, _GroupMessageBatch> messageBatch) async {
    if (messageBatch.isEmpty) {
      return;
    }

    final totalMessages = messageBatch.values.fold(0, (sum, batch) => sum + batch.messages.length);
    final groupCount = messageBatch.length;

    // Strategy 1: If too many messages overall (10+), send a single summary
    if (totalMessages >= 10) {
      await _sendOverallSummaryNotification(totalMessages, groupCount);
      await _updateAllSyncTimes(messageBatch);
      return;
    }

    // Strategy 2: Send per-group notifications (individual or summary)
    for (final batch in messageBatch.values) {
      try {
        if (batch.messages.length <= 3) {
          // Send individual notifications for small batches
          await MessageSyncService.notifyNewMessages(
            groupId: batch.groupId,
            activePubkey: batch.accountPubkey,
            newMessages: batch.messages,
          );
        } else {
          // Send summary notification for larger batches
          await _sendGroupSummaryNotification(batch);
        }

        // Update sync time after successful notification
        await MessageSyncService.setLastSyncTime(
          activePubkey: batch.accountPubkey,
          groupId: batch.groupId,
          time: DateTime.now(),
        );
      } catch (e, stackTrace) {
        _log.warning(
          'Failed to send notifications for group ${batch.groupId}: $e',
          e,
          stackTrace,
        );
      }
    }
  }

  /// Sends a single summary notification for all new messages across all groups.
  Future<void> _sendOverallSummaryNotification(int totalMessages, int groupCount) async {
    try {
      await MessageSyncService.notifyMessageSummary(
        totalMessages: totalMessages,
        groupCount: groupCount,
      );
      _log.info('Sent overall summary notification: $totalMessages messages in $groupCount groups');
    } catch (e, stackTrace) {
      _log.warning('Failed to send overall summary notification: $e', e, stackTrace);
    }
  }

  /// Sends a summary notification for a single group with many messages.
  Future<void> _sendGroupSummaryNotification(_GroupMessageBatch batch) async {
    try {
      await MessageSyncService.notifyGroupSummary(
        groupId: batch.groupId,
        activePubkey: batch.accountPubkey,
        messageCount: batch.messages.length,
      );
      _log.info('Sent group summary notification: ${batch.messages.length} messages in group ${batch.groupId}');
    } catch (e, stackTrace) {
      _log.warning('Failed to send group summary notification: $e', e, stackTrace);
    }
  }

  /// Updates sync times for all groups in the batch.
  Future<void> _updateAllSyncTimes(Map<String, _GroupMessageBatch> messageBatch) async {
    for (final batch in messageBatch.values) {
      try {
        await MessageSyncService.setLastSyncTime(
          activePubkey: batch.accountPubkey,
          groupId: batch.groupId,
          time: DateTime.now(),
        );
      } catch (e, stackTrace) {
        _log.warning(
          'Failed to update sync time for group ${batch.groupId}: $e',
          e,
          stackTrace,
        );
      }
    }
  }

  Future<void> _syncInvitesForAllAccounts() async {
    try {
      final accounts = await getAccounts();
      if (accounts.isEmpty) {
        _log.fine('No accounts found, skipping invite sync');
        return;
      }
      _log.fine('Syncing invites for ${accounts.length} account(s)');
      for (final account in accounts) {
        await _syncInvitesForAccount(account.pubkey);
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing invites for all accounts: $e', e, stackTrace);
    }
  }

  Future<void> _syncInvitesForAccount(String accountPubkey) async {
    try {
      final welcomes = await pendingWelcomes(pubkey: accountPubkey);

      if (welcomes.isEmpty) {
        return;
      }

      final newWelcomes = await MessageSyncService.filterNewInvites(
        activePubkey: accountPubkey,
        welcomes: welcomes,
      );

      if (newWelcomes.isNotEmpty) {
        _log.info('Found ${newWelcomes.length} new invite(s) for account $accountPubkey');

        await MessageSyncService.notifyNewInvites(
          newWelcomes: newWelcomes,
        );

        try {
          await MessageSyncService.setLastInviteSyncTime(
            activePubkey: accountPubkey,
            time: DateTime.now(),
          );
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to update invite sync time for account $accountPubkey after notification. '
            'This may cause duplicate notifications on next sync: $e',
            e,
            stackTrace,
          );
        }
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing invites for account $accountPubkey: $e', e, stackTrace);
    }
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
