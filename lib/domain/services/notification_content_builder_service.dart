import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/notification_content.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class NotificationContentBuilderService {
  static final _logger = Logger('NotificationContentBuilderService');

  final String groupId;
  final String accountPubkey;
  final bool isDM;
  final String groupDisplayName;
  final String title;

  NotificationContentBuilderService._({
    required this.groupId,
    required this.accountPubkey,
    required this.isDM,
    required this.groupDisplayName,
    required this.title,
  });

  static Future<NotificationContentBuilderService> forGroup({
    required String groupId,
    required String accountPubkey,
    required bool isDM,
    required bool showReceiverAccountName,
    Future<Group> Function({required String accountPubkey, required String groupId})? getGroupFn,
    Future<List<String>> Function({required String pubkey, required String groupId})?
    getGroupMembersFn,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    final groupDisplayName = await _getGroupDisplayName(
      isDM: isDM,
      accountPubkey: accountPubkey,
      groupId: groupId,
      getGroupFn: getGroupFn,
      getGroupMembersFn: getGroupMembersFn,
      getUserMetadataFn: getUserMetadataFn,
    );

    final accountReceiverName =
        showReceiverAccountName
            ? await _getUserDisplayName(
              pubkey: accountPubkey,
              getUserMetadataFn: getUserMetadataFn,
            )
            : null;

    final String title =
        showReceiverAccountName
            ? '$groupDisplayName ${'notifications.toAccount'.tr({'accountName': accountReceiverName})}'
            : groupDisplayName;

    return NotificationContentBuilderService._(
      groupId: groupId,
      accountPubkey: accountPubkey,
      isDM: isDM,
      groupDisplayName: groupDisplayName,
      title: title,
    );
  }

  Future<NotificationContent> buildMessageNotification({
    required ChatMessage message,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    final String senderName =
        isDM
            ? groupDisplayName
            : await _getUserDisplayName(
              pubkey: message.pubkey,
              getUserMetadataFn: getUserMetadataFn,
            );

    final String body = _formatMessageBody(
      message: message,
      isDM: isDM,
      senderName: senderName,
    );

    return NotificationContent(
      title: title,
      body: body,
      groupKey: groupId,
      payload: {
        'type': 'new_message',
        'groupId': groupId,
        'messageId': message.id,
        'sender': message.pubkey,
        'accountPubkey': accountPubkey,
        'deepLink': 'whitenoise://chats/$groupId',
      },
    );
  }

  static Future<NotificationContent> buildInviteNotification({
    required Welcome welcome,
    required String accountPubkey,
    required bool showReceiverAccountName,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    final bool isDM = welcome.groupName.isEmpty;

    final String welcomerName = await _getUserDisplayName(
      pubkey: welcome.welcomer,
      blockingDataSync: true,
      getUserMetadataFn: getUserMetadataFn,
    );

    final accountReceiverName =
        showReceiverAccountName
            ? await _getUserDisplayName(
              pubkey: accountPubkey,
              getUserMetadataFn: getUserMetadataFn,
            )
            : null;

    final String title =
        showReceiverAccountName
            ? '$welcomerName ${'notifications.toAccount'.tr({'accountName': accountReceiverName})}'
            : welcomerName;

    final String body =
        isDM
            ? 'notifications.invitedYouToChat'.tr()
            : 'notifications.invitedYouToGroup'.tr({'groupName': welcome.groupName});

    return NotificationContent(
      title: title,
      body: body,
      groupKey: 'invites',
      payload: {
        'type': 'invites_sync',
        'welcomeId': welcome.id,
        'groupId': welcome.mlsGroupId,
        'accountPubkey': accountPubkey,
        'deepLink': 'whitenoise://chats/${welcome.mlsGroupId}?inviteId=${welcome.id}',
      },
    );
  }

  String _formatMessageBody({
    required ChatMessage message,
    required bool isDM,
    required String senderName,
  }) {
    final bool hasMedia = message.mediaAttachments.isNotEmpty;
    final bool hasContent = message.content.isNotEmpty;

    String body;
    final String mediaEmoji = '\u{1F4F7} ';

    if (hasMedia && !hasContent) {
      body =
          isDM
              ? 'notifications.mediaMessage'.tr({'emoji': mediaEmoji})
              : 'notifications.senderMediaMessage'.tr({
                'senderName': senderName,
                'emoji': mediaEmoji,
              });
    } else if (hasContent) {
      final String mediaPrefix = hasMedia ? mediaEmoji : '';
      body =
          isDM ? '$mediaPrefix${message.content}' : '$mediaPrefix$senderName: ${message.content}';
    } else {
      body =
          isDM
              ? 'notifications.sentYouAMessage'.tr()
              : 'notifications.senderSentYouAMessage'.tr({'senderName': senderName});
    }

    return body;
  }

  static Future<String> _getGroupDisplayName({
    required bool isDM,
    required String accountPubkey,
    required String groupId,
    Future<Group> Function({required String accountPubkey, required String groupId})? getGroupFn,
    Future<List<String>> Function({required String pubkey, required String groupId})?
    getGroupMembersFn,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    try {
      if (isDM) {
        return await _getDmDisplayName(
          accountPubkey,
          groupId,
          getGroupMembersFn: getGroupMembersFn,
          getUserMetadataFn: getUserMetadataFn,
        );
      } else {
        final getGroupFunc = getGroupFn ?? getGroup;
        final group = await getGroupFunc(accountPubkey: accountPubkey, groupId: groupId);
        return group.name.isNotEmpty ? group.name : 'notifications.unknownGroup'.tr();
      }
    } catch (e) {
      _logger.warning('Failed to get group display name for $groupId', e);
      return isDM ? 'notifications.directMessage'.tr() : 'notifications.unknownGroup'.tr();
    }
  }

  static Future<String> _getDmDisplayName(
    String accountPubkey,
    String groupId, {
    Future<List<String>> Function({required String pubkey, required String groupId})?
    getGroupMembersFn,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    try {
      final getGroupMembersFunc = getGroupMembersFn ?? groupMembers;
      final members = await getGroupMembersFunc(pubkey: accountPubkey, groupId: groupId);
      if (members.isEmpty) return 'notifications.directMessage'.tr();

      final otherMemberPubkey = members.firstWhere(
        (memberPubkey) => memberPubkey != accountPubkey,
        orElse: () => members.first,
      );

      return await _getUserDisplayName(
        pubkey: otherMemberPubkey,
        getUserMetadataFn: getUserMetadataFn,
      );
    } catch (e) {
      _logger.warning('Failed to get DM display name for $groupId', e);
      return 'notifications.directMessage'.tr();
    }
  }

  static Future<String> _getUserDisplayName({
    required String pubkey,
    bool blockingDataSync = false,
    Future<FlutterMetadata> Function({required String pubkey, bool blockingDataSync})?
    getUserMetadataFn,
  }) async {
    try {
      final getUserMetadataFunc = getUserMetadataFn ?? userMetadata;
      final metadata = await getUserMetadataFunc(
        pubkey: pubkey,
        blockingDataSync: blockingDataSync,
      );
      if (metadata.displayName?.isNotEmpty == true) {
        return metadata.displayName!;
      } else if (metadata.name?.isNotEmpty == true) {
        return metadata.name!;
      }
    } catch (e) {
      _logger.warning('Failed to get user metadata for $pubkey', e);
    }
    return 'shared.unknownUser'.tr();
  }
}
