import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/displayed_chat_service.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';
import 'package:whitenoise/domain/services/notification_id_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/users.dart';
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
    required String activePubkey,
    required List<ChatMessage> newMessages,
  }) async {
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to notifyNewMessages');
      return;
    }
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to notifyNewMessages');
      return;
    }

    final isDisplayed = await DisplayedChatService.isChatDisplayed(groupId);
    if (isDisplayed) {
      _logger.fine('Skipping notifications for displayed chat: $groupId');
      return;
    }

    // Determine if it's a DM or group
    bool isDM = false;
    String groupDisplayName = 'Unknown';
    try {
      final group = await getGroup(accountPubkey: activePubkey, groupId: groupId);
      isDM = await group.isDirectMessageType(accountPubkey: activePubkey);
      groupDisplayName =
          isDM
              ? await _resolveDmDisplayName(activePubkey, groupId, group)
              : _resolveGroupChatDisplayName(group);
    } catch (e) {
      _logger.warning('Failed to determine DM/group status for $groupId', e);
      groupDisplayName = await getGroupDisplayName(groupId, activePubkey);
    }

    for (final message in newMessages) {
      try {
        // Get sender's display name
        String senderName = 'Unknown';
        try {
          final metadata = await userMetadata(pubkey: message.pubkey, blockingDataSync: true);
          if (metadata.displayName?.isNotEmpty == true) {
            senderName = metadata.displayName!;
          } else if (metadata.name?.isNotEmpty == true) {
            senderName = metadata.name!;
          }
        } catch (e) {
          _logger.warning('Failed to get sender metadata for ${message.pubkey}', e);
        }

        // Format title and body based on DM or group
        final String title = isDM ? senderName : groupDisplayName;

        // Check if message has media and/or content
        final bool hasMedia = message.mediaAttachments.isNotEmpty;
        final bool hasContent = message.content.isNotEmpty;

        String body;
        final String mediaEmoji = '\u{1F4F7} ';
        if (hasMedia && !hasContent) {
          // Media message without content
          body = isDM ? '$mediaEmoji Media' : '$mediaEmoji $senderName: Media';
        } else if (hasContent) {
          // Message with content (may also have media)
          final String mediaPrefix = hasMedia ? mediaEmoji : '';
          body =
              isDM
                  ? '$mediaPrefix${message.content}'
                  : '$mediaPrefix$senderName: ${message.content}';
        } else {
          body = isDM ? 'Sent you a message' : '$senderName: Sent you a message';
        }

        await NotificationService.showMessageNotification(
          id: await NotificationIdService.getIdFor(
            key: 'new_message:$groupId:${message.id}',
          ),
          title: title,
          body: body,
          groupKey: groupId,
          payload: jsonEncode({
            'type': 'new_message',
            'groupId': groupId,
            'messageId': message.id,
            'sender': message.pubkey,
            'deepLink': 'whitenoise://chats/$groupId',
          }),
        );
        _logger.info('Notification shown for message ${message.id}');
      } catch (e) {
        _logger.warning('Failed to show notification for message ${message.id}', e);
      }
    }
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
  }) async {
    for (final welcome in newWelcomes) {
      try {
        // Determine if it's a DM or group
        // If groupName is empty, it's a DM
        // Otherwise, it's a group
        final bool isDM = welcome.groupName.isEmpty;

        // Get the welcomer's display name
        String welcomerName = 'Unknown';
        try {
          final metadata = await userMetadata(pubkey: welcome.welcomer, blockingDataSync: true);
          if (metadata.displayName?.isNotEmpty == true) {
            welcomerName = metadata.displayName!;
          } else if (metadata.name?.isNotEmpty == true) {
            welcomerName = metadata.name!;
          }
        } catch (e) {
          _logger.warning('Failed to get welcomer metadata for ${welcome.welcomer}', e);
        }

        final String title = welcomerName;
        final String body = isDM ? 'Invited you to chat' : 'Invited you to ${welcome.groupName}';

        await NotificationService.showInviteNotification(
          id: await NotificationIdService.getIdFor(
            key: 'invites_sync:${welcome.id}',
          ),
          title: title,
          body: body,
          groupKey: 'invites',
          payload: jsonEncode({
            'type': 'invites_sync',
            'welcomeId': welcome.id,
            'groupId': welcome.mlsGroupId,
            'deepLink': 'whitenoise://chats/${welcome.mlsGroupId}?inviteId=${welcome.id}',
          }),
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
      _logger.info('Last invite sync time for account $activePubkey Set to ${time.toLocal()}');
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

  static Future<String> getGroupDisplayName(String groupId, String activePubkey) async {
    if (groupId.isEmpty) {
      _logger.warning('Empty groupId provided to getGroupDisplayName');
      return 'Unknown Group';
    }
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to getGroupDisplayName');
      return 'Unknown Group';
    }

    try {
      final group = await getGroup(accountPubkey: activePubkey, groupId: groupId);
      final isDM = await group.isDirectMessageType(accountPubkey: activePubkey);
      return isDM
          ? await _resolveDmDisplayName(activePubkey, groupId, group)
          : _resolveGroupChatDisplayName(group);
    } catch (e) {
      _logger.warning('Get group name for $groupId', e);
      return 'Group Chat';
    }
  }

  static Future<String> _resolveDmDisplayName(
    String activePubkey,
    String groupId,
    dynamic group,
  ) async {
    final members = await groupMembers(pubkey: activePubkey, groupId: groupId);
    if (members.isEmpty) {
      return 'Direct Message';
    }

    final otherMemberPubkey = members.firstWhere(
      (memberPubkey) => memberPubkey != activePubkey,
      orElse: () => members.first,
    );

    try {
      final metadata = await userMetadata(pubkey: otherMemberPubkey, blockingDataSync: true);
      if (metadata.displayName?.isNotEmpty == true) {
        return metadata.displayName!;
      }
    } catch (e) {
      _logger.warning('Get user metadata for $otherMemberPubkey', e);
    }

    return 'Unknown';
  }

  static String _resolveGroupChatDisplayName(dynamic group) {
    return group.name.isNotEmpty ? group.name : 'Unknown Group';
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
