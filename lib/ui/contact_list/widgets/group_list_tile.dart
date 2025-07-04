import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/utils/timeago_formatter.dart';

class GroupListTile extends ConsumerWidget {
  const GroupListTile({
    super.key,
    this.lastMessage,
    required this.group,
  });

  final GroupData group;
  final MessageModel? lastMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserNpub = ref.watch(nostrKeysProvider).npub ?? '';
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
    final displayImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId, currentUserNpub);

    return InkWell(
      onTap: () => Routes.goToChat(context, group.mlsGroupId),

      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            ContactAvatar(
              imageUrl: displayImage ?? '',
              displayName: displayName,

              size: 56.r,
            ),
            Gap(8.w),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: lastMessage != null ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        lastMessage?.createdAt.timeago().capitalizeFirst ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  if (lastMessage != null) ...[
                    Gap(4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 32.w,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage!.content ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: context.colors.mutedForeground,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const MessageReadStatus(
                          // ignore: avoid_redundant_argument_values
                          lastSentMessageStatus: MessageStatus.sent,
                          unreadCount: 0,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReadStatus extends StatelessWidget {
  const MessageReadStatus({
    super.key,
    this.lastSentMessageStatus = MessageStatus.sent,
    required this.unreadCount,
  });

  final MessageStatus lastSentMessageStatus;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) {
      return Image.asset(
        lastSentMessageStatus.imagePath,
        width: 17.5.w,
        height: 17.5.w,
        color: lastSentMessageStatus.color(context),
      );
    }
    return Container(
      padding:
          unreadCount > 99
              ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h)
              : EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: unreadCount > 99 ? BorderRadius.circular(12.r) : null,
        shape: unreadCount > 99 ? BoxShape.rectangle : BoxShape.circle,
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: TextStyle(
          fontSize: 12.sp,
          color: context.colors.primaryForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
