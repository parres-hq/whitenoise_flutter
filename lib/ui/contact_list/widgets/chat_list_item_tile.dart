import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/contact_list/widgets/message_read_status.dart';
import 'package:whitenoise/ui/contact_list/widgets/welcome_tile.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/utils/string_extensions.dart';
import 'package:whitenoise/utils/timeago_formatter.dart';

class ChatListItemTile extends ConsumerWidget {
  const ChatListItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final ChatListItem item;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (item.type) {
      case ChatListItemType.chat:
        return _buildChatTile(context, ref);
      case ChatListItemType.welcome:
        return WelcomeTile(item: item);
    }
  }

  Widget _buildChatTile(BuildContext context, WidgetRef ref) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final group = item.group;
    if (group == null) {
      return const SizedBox.shrink();
    }
    final groupType = groupsNotifier.getCachedGroupType(group.mlsGroupId);
    // If group type is not cached yet, use FutureBuilder to handle the async loading
    if (groupType == null) {
      return FutureBuilder<GroupType>(
        future: groupsNotifier.getGroupTypeById(group.mlsGroupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading state with basic info while determining group type
            final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
            final displayImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId);
            return _buildChatTileContent(context, displayName, displayImage, group);
          }

          final resolvedGroupType = snapshot.data ?? GroupType.group;
          return _buildChatTileForType(context, ref, group, resolvedGroupType);
        },
      );
    }

    return _buildChatTileForType(context, ref, group, groupType);
  }

  Widget _buildChatTileForType(
    BuildContext context,
    WidgetRef ref,
    Group group,
    GroupType groupType,
  ) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    // For DM chats, get the other member and use metadata cache for better user info
    if (groupType == GroupType.directMessage) {
      return FutureBuilder(
        future: ref.getDMChatData(group.mlsGroupId),
        builder: (context, AsyncSnapshot<DMChatData?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading state with basic info
            final displayName = snapshot.data?.displayName ?? '';
            return _buildChatTileContent(context, displayName, null, group);
          }

          final data = snapshot.data;
          if (data == null) {
            // Fallback to existing logic if no data
            final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
            final displayImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId);
            return _buildChatTileContent(context, displayName, displayImage, group);
          }

          return _buildChatTileContent(context, data.displayName, data.displayImage, group);
        },
      );
    }

    final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
    final displayImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId);

    return _buildChatTileContent(context, displayName, displayImage, group);
  }

  Widget _buildChatTileContent(
    BuildContext context,
    String displayName,
    String? displayImage,
    Group group,
  ) {
    final displayImageUrl = displayImage ?? '';
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
        Routes.goToChat(context, group.mlsGroupId);
      },
      child: Padding(
        padding: EdgeInsets.only(left: 8.w, right: 16.w, top: 8.h, bottom: 8.h),
        child: Row(
          children: [
            WnAvatar(
              imageUrl: displayImageUrl,
              displayName: displayName,
              size: 56.r,
              showBorder: displayImageUrl.isEmpty,
            ),
            Gap(8.w),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    item.lastMessage != null ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
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
                      Text(
                        item.lastMessage?.createdAt.timeago().capitalizeFirst ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  if (item.lastMessage != null) ...[
                    Gap(4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 32.w,
                      children: [
                        Expanded(
                          child: Text(
                            _getMessagePreview(item.lastMessage!),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: context.colors.mutedForeground,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const MessageReadStatus(
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

  String _getMessagePreview(MessageModel message) {
    final content = message.content ?? '';

    if (message.isMe) {
      return 'You: $content';
    }
    return content;
  }
}
