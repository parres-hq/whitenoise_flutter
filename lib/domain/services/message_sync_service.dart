import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
/// - Resolving group display names for notifications
class MessageSyncService {
  static final _logger = Logger('MessageSyncService');
  static SharedPreferences? _prefs;
  static const Duration _messageSyncBuffer = Duration(seconds: 1);
  static const Duration _defaultLookbackWindow = Duration(hours: 1);
  static const int _pubkeyDisplayLength = 8;

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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
      final groups = await activeGroups(pubkey: activePubkey);
      final matching = groups.where((g) => g.mlsGroupId == groupId);
      if (matching.isEmpty) {
        _logger.warning('Group not found for $groupId');
        return 'Group Chat';
      }
      final group = matching.first;

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
      final metadata = await userMetadata(pubkey: otherMemberPubkey);
      if (metadata.displayName?.isNotEmpty == true) {
        return metadata.displayName!;
      }
    } catch (e) {
      _logger.warning('Get user metadata for $otherMemberPubkey', e);
    }

    return _formatMemberDisplayName(otherMemberPubkey);
  }

  static String _resolveGroupChatDisplayName(dynamic group) {
    return group.name.isNotEmpty ? group.name : 'Unknown Group';
  }

  static String _formatMemberDisplayName(String pubkey) {
    return pubkey.substring(0, _pubkeyDisplayLength);
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

    final String groupDisplayName = await getGroupDisplayName(groupId, activePubkey);

    for (final message in newMessages) {
      try {
        await NotificationService.showMessageNotification(
          id: await NotificationIdService.getIdFor(
            key: 'new_message:$groupId:${message.id}',
          ),
          title: groupDisplayName,
          body: message.content,
          groupKey: groupId,
          payload: jsonEncode({
            'type': 'new_message',
            'groupId': groupId,
            'messageId': message.id,
            'sender': message.pubkey,
          }),
        );
        _logger.info('Notification shown for message ${message.id}');
      } catch (e) {
        _logger.warning('Failed to show notification for message ${message.id}', e);
      }
    }
  }

  static Future<void> notifyNewInvites({
    required List<Welcome> newWelcomes,
  }) async {
    for (final welcome in newWelcomes) {
      try {
        await NotificationService.showInviteNotification(
          id: await NotificationIdService.getIdFor(
            key: 'invites_sync:${welcome.id}',
          ),
          title: 'New Invitations',
          body: 'New group invitation',
          groupKey: 'invites',
          payload: jsonEncode({
            'type': 'invites_sync',
            'welcomeId': welcome.id,
          }),
        );
        _logger.info('Notification shown for welcome ${welcome.id}');
      } catch (e) {
        _logger.warning('Failed to show notification for welcome ${welcome.id}', e);
      }
    }
  }

  static Future<DateTime?> getLastSyncTime({
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

  static Future<void> setLastSyncTime({
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

  /// Filters invites to find new ones that should trigger notifications.
  ///
  /// Excludes invites that have already been processed based on the last sync timestamp.
  /// Uses the same pattern as message filtering for consistency.
  ///
  /// Returns an empty list for invalid inputs.
  static Future<List<Welcome>> filterNewInvites({
    required String activePubkey,
    required List<Welcome> welcomes,
  }) async {
    if (activePubkey.isEmpty) {
      _logger.warning('Empty activePubkey provided to filterNewInvites');
      return [];
    }

    try {
      final lastSyncTime = await getLastInviteSyncTime(activePubkey: activePubkey);

      // If no previous sync, use default lookback window to avoid notifying old invites
      final cutoffTime = lastSyncTime ?? DateTime.now().subtract(_defaultLookbackWindow);
      final cutoffMillis = BigInt.from(cutoffTime.millisecondsSinceEpoch);

      final newWelcomes =
          welcomes.where((welcome) {
            // Compare BigInt timestamps directly
            return welcome.createdAt > cutoffMillis;
          }).toList();

      _logger.fine(
        'Filtered ${newWelcomes.length} new invite(s) from ${welcomes.length} total for account $activePubkey '
        '(lastSyncTime: $lastSyncTime, cutoffTime: $cutoffTime)',
      );

      return newWelcomes;
    } catch (e) {
      _logger.warning('Failed to filter new invites for account $activePubkey', e);
      return [];
    }
  }

  /// Gets the last invite sync timestamp for an account.
  ///
  /// Returns null if no previous sync has been recorded.
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

  /// Sets the last invite sync timestamp for an account.
  ///
  /// This timestamp is used to filter out already-notified invites on the next sync.
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
}
