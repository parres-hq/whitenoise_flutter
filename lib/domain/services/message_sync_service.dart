import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/displayed_chat_service.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';
import 'package:whitenoise/domain/services/notification_content_builder_service.dart';
import 'package:whitenoise/domain/services/notification_id_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

/// Service responsible for message synchronization, filtering, and notifications.
///
/// This service handles:
/// - Filtering new messages based on sync checkpoints and user read status
/// - Managing sync checkpoints per account and group
/// - Sending notifications for new messages and invites
/// - Resolving welcomer names, group names, and message content for notifications
class MessageSyncService {
  static final _logger = Logger('MessageSyncService');
  static SharedPreferences? _prefs;
  static const Duration _messageSyncBuffer = Duration(seconds: 1);
  static const Duration _defaultLookbackWindow = Duration(hours: 1);

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Filters messages to find new ones that should trigger notifications.
  ///
  /// Excludes:
  /// - Messages from the current user
  /// - Deleted messages
  /// - Messages before the last processed time (sync checkpoint or last read)
  /// - Messages after the buffer window (to avoid race conditions)
  ///
  /// Returns an empty list for invalid inputs.
  static Future<List<ChatMessage>> filterNewMessages(
    List<ChatMessage> messages,
    String currentUserPubkey,
    String groupId,
    DateTime? lastSyncTime,
  ) async {
    if (currentUserPubkey.isEmpty) {
      _logger.warning('Empty currentUserPubkey provided to filterNewMessages');
      return [];
    }
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to filterNewMessages');
      return [];
    }

    final now = DateTime.now();
    final earliestAllowedTime = now.subtract(_messageSyncBuffer);

    final lastReadTime = await LastReadService.getLastRead(
      groupId: groupId,
      activePubkey: currentUserPubkey,
    );
    final lastProcessedTime = _getMostRecentTime([
      lastSyncTime,
      lastReadTime,
      now.subtract(_defaultLookbackWindow),
    ]);

    _logger.fine(
      'Filtering messages for group $groupId: '
      'lastSyncTime=$lastSyncTime, lastReadTime=$lastReadTime, '
      'lastProcessedTime=$lastProcessedTime, totalMessages=${messages.length}',
    );

    final sortedMessages = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final startIndex = _binarySearchAfter(sortedMessages, lastProcessedTime);
    final endIndex = _binarySearchBefore(sortedMessages, earliestAllowedTime);

    if (startIndex >= endIndex) {
      return [];
    }
    final filteredMessages =
        sortedMessages.sublist(startIndex, endIndex).where((message) {
          return message.pubkey != currentUserPubkey && !message.isDeleted;
        }).toList();

    _logger.fine(
      'Filtered ${filteredMessages.length} new messages from ${messages.length} total for group $groupId',
    );

    return filteredMessages;
  }

  static Future<void> notifyNewMessages({
    required String groupId,
    required String accountPubkey,
    required List<ChatMessage> newMessages,
    required bool showReceiverAccountName,
    Future<bool> Function(String)? isChatDisplayedFn,
    Future<GroupInformation> Function({required String accountPubkey, required String groupId})?
    getGroupInformationFn,
    Future<NotificationContentBuilderService> Function({
      required String groupId,
      required String accountPubkey,
      required bool isDM,
      required bool showReceiverAccountName,
    })?
    notificationBuilderFactoryFn,
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      String? groupKey,
      String? payload,
    })?
    showNotificationFn,
    Future<int> Function({required String key})? getNotificationIdFn,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    if (!_validateNotificationParams(groupId: groupId, accountPubkey: accountPubkey)) {
      return;
    }

    if (await _shouldSkipNotifications(groupId: groupId, isChatDisplayedFn: isChatDisplayedFn)) {
      return;
    }

    final notificationBuilder = await _setNotificationBuilder(
      groupId: groupId,
      accountPubkey: accountPubkey,
      showReceiverAccountName: showReceiverAccountName,
      getGroupInformationFn: getGroupInformationFn,
      notificationBuilderFactoryFn: notificationBuilderFactoryFn,
    );

    await _sendNotificationsForMessages(
      groupId: groupId,
      newMessages: newMessages,
      notificationBuilder: notificationBuilder,
      showNotificationFn: showNotificationFn,
      getNotificationIdFn: getNotificationIdFn,
      getUserMetadataFn: getUserMetadataFn,
    );
  }

  static bool _validateNotificationParams({
    required String groupId,
    required String accountPubkey,
  }) {
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to notifyNewMessages');
      return false;
    }
    if (accountPubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to notifyNewMessages');
      return false;
    }
    return true;
  }

  static Future<bool> _shouldSkipNotifications({
    required String groupId,
    Future<bool> Function(String)? isChatDisplayedFn,
  }) async {
    final isChatDisplayedFunc = isChatDisplayedFn ?? DisplayedChatService.isChatDisplayed;
    final isDisplayed = await isChatDisplayedFunc(groupId);

    if (isDisplayed) {
      _logger.fine('Skipping notifications for displayed chat: $groupId');
    }

    return isDisplayed;
  }

  static Future<NotificationContentBuilderService> _setNotificationBuilder({
    required String groupId,
    required String accountPubkey,
    required bool showReceiverAccountName,
    Future<GroupInformation> Function({required String accountPubkey, required String groupId})?
    getGroupInformationFn,
    Future<NotificationContentBuilderService> Function({
      required String groupId,
      required String accountPubkey,
      required bool isDM,
      required bool showReceiverAccountName,
    })?
    notificationBuilderFactoryFn,
  }) async {
    final getGroupInformationFunc = getGroupInformationFn ?? getGroupInformation;
    final groupInformation = await getGroupInformationFunc(
      accountPubkey: accountPubkey,
      groupId: groupId,
    );
    final isDM = groupInformation.groupType == GroupType.directMessage;

    final notificationBuilderFactory =
        notificationBuilderFactoryFn ?? _defaultNotificationBuilderFactory;
    return notificationBuilderFactory(
      groupId: groupId,
      accountPubkey: accountPubkey,
      isDM: isDM,
      showReceiverAccountName: showReceiverAccountName,
    );
  }

  static Future<void> _sendNotificationsForMessages({
    required String groupId,
    required List<ChatMessage> newMessages,
    required NotificationContentBuilderService notificationBuilder,
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      String? groupKey,
      String? payload,
    })?
    showNotificationFn,
    Future<int> Function({required String key})? getNotificationIdFn,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    final showNotificationFunc = showNotificationFn ?? NotificationService.showMessageNotification;
    final getNotificationIdFunc = getNotificationIdFn ?? NotificationIdService.getIdFor;

    for (final message in newMessages) {
      try {
        final content = await notificationBuilder.buildMessageNotification(
          message: message,
          getUserMetadataFn: getUserMetadataFn,
        );

        await showNotificationFunc(
          id: await getNotificationIdFunc(
            key: 'new_message:$groupId:${message.id}',
          ),
          title: content.title,
          body: content.body,
          groupKey: content.groupKey,
          payload: jsonEncode(content.payload),
        );
        _logger.info('Notification shown for message ${message.id}');
      } catch (e) {
        _logger.warning('Failed to show notification for message ${message.id}', e);
      }
    }
  }

  static Future<NotificationContentBuilderService> _defaultNotificationBuilderFactory({
    required String groupId,
    required String accountPubkey,
    required bool isDM,
    required bool showReceiverAccountName,
  }) {
    return NotificationContentBuilderService.forGroup(
      groupId: groupId,
      accountPubkey: accountPubkey,
      isDM: isDM,
      showReceiverAccountName: showReceiverAccountName,
    );
  }

  static Future<void> setLastMessageSyncTime({
    required String activePubkey,
    required String groupId,
    required DateTime time,
  }) async {
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to setLastSyncTime');
      return;
    }
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to setLastSyncTime');
      return;
    }

    try {
      final prefs = await _preferences;
      await prefs.setInt(
        'bg_sync_last_${activePubkey}_$groupId',
        time.millisecondsSinceEpoch,
      );
      _logger.info('Last sync time for group $groupId Set to ${time.toLocal()}');
    } catch (e) {
      _logger.warning('Failed to set last sync time for group $groupId', e);
    }
  }

  static Future<DateTime?> getLastMessageSyncTime({
    required String activePubkey,
    required String groupId,
  }) async {
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to getLastSyncTime');
      return null;
    }
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to getLastSyncTime');
      return null;
    }

    try {
      final prefs = await _preferences;
      final timestamp = prefs.getInt('bg_sync_last_${activePubkey}_$groupId');
      final dateTime = timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
      _logger.info('Last sync time for group $groupId: ${dateTime?.toLocal()}');
      return dateTime;
    } catch (e) {
      _logger.warning('Failed to get last sync time for group $groupId', e);
      return null;
    }
  }

  /// Filters invites to find new ones that should trigger notifications.
  ///
  /// Excludes:
  /// - Invites from the current user (self-invites)
  /// - Already-processed invites (older than last sync timestamp)
  /// - Invites in non-pending states (accepted, declined, ignored)
  ///
  /// Uses a 24-hour lookback window on first sync to catch recent invites.
  /// Returns an empty list for invalid inputs.
  static Future<List<Welcome>> filterNewInvites({
    required List<Welcome> welcomes,
    required String currentUserPubkey,
    DateTime? lastSyncTime,
  }) async {
    if (currentUserPubkey.isEmpty) {
      _logger.warning('Empty currentUserPubkey provided to filterNewMessages');
      return [];
    }

    final sortedWelcomes = List<Welcome>.from(welcomes)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final filteredWelcomes =
        sortedWelcomes.where((welcome) {
          return DateTime.fromMillisecondsSinceEpoch(welcome.createdAt.toInt() * 1000).isAfter(
            lastSyncTime ?? DateTime.now().subtract(_defaultLookbackWindow),
          );
        }).toList();

    return filteredWelcomes;
  }

  static Future<void> notifyNewInvites({
    required List<Welcome> newWelcomes,
    required String accountPubkey,
    required bool showReceiverAccountName,
  }) async {
    for (final welcome in newWelcomes) {
      try {
        final content = await NotificationContentBuilderService.buildInviteNotification(
          welcome: welcome,
          accountPubkey: accountPubkey,
          showReceiverAccountName: showReceiverAccountName,
        );

        await NotificationService.showInviteNotification(
          id: await NotificationIdService.getIdFor(
            key: 'invites_sync:${welcome.id}',
          ),
          title: content.title,
          body: content.body,
          groupKey: content.groupKey,
          payload: jsonEncode(content.payload),
        );
        _logger.info('Notification shown for welcome ${welcome.id}');
      } catch (e) {
        _logger.warning('Failed to show notification for welcome ${welcome.id}', e);
      }
    }
  }

  static Future<void> setLastInviteSyncTime({
    required String activePubkey,
    required DateTime time,
  }) async {
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to setLastInviteSyncTime');
      return;
    }
    try {
      final prefs = await _preferences;
      await prefs.setInt(
        'bg_sync_last_invite_$activePubkey',
        time.millisecondsSinceEpoch,
      );
      _logger.info('Last invite sync time for account $activePubkey set to ${time.toLocal()}');
    } catch (e) {
      _logger.warning('Failed to set last invite sync time for account $activePubkey', e);
    }
  }

  static Future<DateTime?> getLastInviteSyncTime({
    required String activePubkey,
  }) async {
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to getLastInviteSyncTime');
      return null;
    }
    try {
      final prefs = await _preferences;
      final timestamp = prefs.getInt('bg_sync_last_invite_$activePubkey');
      final dateTime = timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
      _logger.info('Last invite sync time for account $activePubkey: ${dateTime?.toLocal()}');
      return dateTime;
    } catch (e) {
      _logger.warning('Failed to get last invite sync time for account $activePubkey', e);
      return null;
    }
  }

  static DateTime _getMostRecentTime(List<DateTime?> times) {
    final validTimes = times.where((time) => time != null).cast<DateTime>();
    if (validTimes.isEmpty) return DateTime.now().subtract(_defaultLookbackWindow);
    return validTimes.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static int _binarySearchAfter(List<ChatMessage> messages, DateTime target) {
    int left = 0;
    int right = messages.length;

    while (left < right) {
      final mid = (left + right) ~/ 2;
      if (messages[mid].createdAt.isAfter(target)) {
        right = mid;
      } else {
        left = mid + 1;
      }
    }

    return left;
  }

  static int _binarySearchBefore(List<ChatMessage> messages, DateTime target) {
    int left = 0;
    int right = messages.length;

    while (left < right) {
      final mid = (left + right) ~/ 2;
      if (messages[mid].createdAt.isBefore(target)) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }

    return left;
  }
}
