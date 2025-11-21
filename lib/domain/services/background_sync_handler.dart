import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/services/localization_service.dart';
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
      await _initializeLocalization();
      _log.info('BackgroundSyncHandler initialized at $timestamp');
    } catch (e, stackTrace) {
      _log.severe('Error initializing BackgroundSyncHandler: $e', e, stackTrace);
    }
  }

  Future<void> _initializeLocalization() async {
    try {
      final String localeCode = LocalizationService.getDeviceLocale();
      await LocalizationService.load(Locale(localeCode));
      _log.info('Localization initialized for background isolate with locale: $localeCode');
    } catch (e, stackTrace) {
      _log.warning('Failed to initialize localization, falling back to English: $e', e, stackTrace);
      try {
        await LocalizationService.load(const Locale('en'));
      } catch (fallbackError) {
        _log.severe('Failed to load fallback locale: $fallbackError');
      }
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
      final showAccountsReceiverName = accounts.length > 1;
      final activePubkey = await AccountSecureStorageService.getActivePubkey();
      for (final account in accounts) {
        final showReceiverAccountName = showAccountsReceiverName && account.pubkey != activePubkey;
        try {
          await _syncMessagesForAccount(
            accountPubkey: account.pubkey,
            showReceiverAccountName: showReceiverAccountName,
          );
        } catch (e, stackTrace) {
          _log.warning('Message sync failed for ${account.pubkey}: $e', e, stackTrace);
        }
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing messages for all accounts: $e', e, stackTrace);
    }
  }

  Future<void> _syncMessagesForAccount({
    required String accountPubkey,
    required bool showReceiverAccountName,
  }) async {
    try {
      final groups = await activeGroups(pubkey: accountPubkey);
      _log.fine('Found ${groups.length} active group(s) for account $accountPubkey');
      for (final group in groups) {
        await _syncMessagesForGroup(
          accountPubkey: accountPubkey,
          groupId: group.mlsGroupId,
          showReceiverAccountName: showReceiverAccountName,
        );
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing messages for account $accountPubkey: $e', e, stackTrace);
    }
  }

  Future<void> _syncMessagesForGroup({
    required String accountPubkey,
    required String groupId,
    required bool showReceiverAccountName,
  }) async {
    try {
      final lastSyncTime = await MessageSyncService.getLastMessageSyncTime(
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
          accountPubkey: accountPubkey,
          newMessages: newMessages,
          showReceiverAccountName: showReceiverAccountName,
        );
        try {
          final lastMessageTime = newMessages
              .map((m) => m.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: accountPubkey,
            groupId: groupId,
            time: lastMessageTime,
          );
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to update sync time for group $groupId after notification. '
            'This may cause duplicate notifications on next sync: $e',
            e,
            stackTrace,
          );
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
      final showAccountsReceiverName = accounts.length > 1;
      final activePubkey = await AccountSecureStorageService.getActivePubkey();
      for (final account in accounts) {
        final showReceiverAccountName = showAccountsReceiverName && account.pubkey != activePubkey;
        await _syncInvitesForAccount(account.pubkey, showReceiverAccountName);
      }
    } catch (e, stackTrace) {
      _log.warning('Error syncing invites for all accounts: $e', e, stackTrace);
    }
  }

  Future<void> _syncInvitesForAccount(String accountPubkey, bool showReceiverAccountName) async {
    try {
      final lastSyncTime = await MessageSyncService.getLastInviteSyncTime(
        activePubkey: accountPubkey,
      );
      final welcomes = await pendingWelcomes(pubkey: accountPubkey);
      if (welcomes.isEmpty) {
        _log.fine('No pending invites found for account $accountPubkey, skipping invite sync');
        return;
      }

      _log.fine('Found ${welcomes.length} pending welcome(s) for account $accountPubkey');

      final newWelcomes = await MessageSyncService.filterNewInvites(
        welcomes: welcomes,
        currentUserPubkey: accountPubkey,
        lastSyncTime: lastSyncTime,
      );

      if (newWelcomes.isNotEmpty) {
        _log.info(
          'Found ${newWelcomes.length} new invite(s) for account $accountPubkey (${welcomes.length} total pending)',
        );

        await MessageSyncService.notifyNewInvites(
          newWelcomes: newWelcomes,
          accountPubkey: accountPubkey,
          showReceiverAccountName: showReceiverAccountName,
        );

        await MessageSyncService.setLastInviteSyncTime(
          activePubkey: accountPubkey,
          time: DateTime.now(),
        );
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
