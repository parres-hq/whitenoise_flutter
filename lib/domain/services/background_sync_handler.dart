import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show fetchAggregatedMessagesForGroup;
import 'package:whitenoise/src/rust/api/welcomes.dart' show pendingWelcomes;
import 'package:whitenoise/src/rust/frb_generated.dart';

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
      await _syncMessagesForAllAccounts();
      await _syncInvitesForAllAccounts();
      _log.fine('Background sync completed at $timestamp');
    } catch (e, stackTrace) {
      _log.severe('Error in onRepeatEvent: $e', e, stackTrace);
    }
    FlutterForegroundTask.sendDataToMain(timestamp.millisecondsSinceEpoch);
  }

  Future<void> _syncMessagesForAllAccounts() async {
    try {
      final accounts = await getAccounts();
      if (accounts.isEmpty) {
        _log.fine('No accounts found, skipping message sync');
        return;
      }
      _log.fine('Syncing messages for ${accounts.length} account(s)');
      for (final account in accounts) {
        await _syncMessagesForAccount(account.pubkey);
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing messages for all accounts: $e', e, stackTrace);
    }
  }

  Future<void> _syncMessagesForAccount(String accountPubkey) async {
    try {
      final groups = await activeGroups(pubkey: accountPubkey);
      _log.fine('Found ${groups.length} active group(s) for account $accountPubkey');
      for (final group in groups) {
        await _syncMessagesForGroup(
          accountPubkey: accountPubkey,
          groupId: group.mlsGroupId,
        );
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing messages for account $accountPubkey: $e', e, stackTrace);
    }
  }

  Future<void> _syncMessagesForGroup({
    required String accountPubkey,
    required String groupId,
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
        _log.info('Found ${newMessages.length} new message(s) in group $groupId');
        await MessageSyncService.notifyNewMessages(
          groupId: groupId,
          activePubkey: accountPubkey,
          newMessages: newMessages,
        );
        try {
          await MessageSyncService.setLastSyncTime(
            activePubkey: accountPubkey,
            groupId: groupId,
            time: DateTime.now(),
          );
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to update sync time for group $groupId after notification. '
            'This may cause duplicate notifications on next sync: $e',
            e,
            stackTrace,
          );
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing messages for group $groupId: $e', e, stackTrace);
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
          await MessageSyncService.markInvitesAsNotified(
            activePubkey: accountPubkey,
            inviteIds: newWelcomes.map((w) => w.id).toList(),
          );
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to mark invites as notified for account $accountPubkey after notification. '
            'This may cause duplicate notifications on next sync: $e',
            e,
            stackTrace,
          );
          rethrow;
        }
      }

      await MessageSyncService.cleanupNotifiedInvites(
        activePubkey: accountPubkey,
        currentPendingIds: welcomes.map((w) => w.id).toSet(),
      );
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
