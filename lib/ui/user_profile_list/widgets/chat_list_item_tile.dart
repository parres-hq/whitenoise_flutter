import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_skeleton_container.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/message_read_status.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/welcome_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
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
    final fallbackName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
    final fallbackImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId);

    // Non-DM chats use fallback data directly
    if (groupType != GroupType.directMessage) {
      return _buildChatTileContent(context, fallbackName, fallbackImage, group);
    }

    // DM chats get enhanced user info
    return FutureBuilder<DMChatData?>(
      future: ref.getDMChatData(group.mlsGroupId),
      builder: (context, snapshot) {
        final data = snapshot.data;

        final displayName = _getDisplayName(snapshot, data, fallbackName);
        final displayImage = _getDisplayImage(snapshot, data, fallbackImage);

        return _buildChatTileContent(context, displayName, displayImage, group);
      },
    );
  }

  String _getDisplayName(AsyncSnapshot<DMChatData?> snapshot, DMChatData? data, String fallback) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return fallback.isEmpty ? 'shared.loading'.tr() : fallback;
    }
    final String name = data?.displayName ?? '';
    return name.isNotEmpty ? name : fallback;
  }

  String? _getDisplayImage(
    AsyncSnapshot<DMChatData?> snapshot,
    DMChatData? data,
    String? fallback,
  ) {
    return snapshot.connectionState == ConnectionState.waiting
        ? fallback
        : (data?.displayImage ?? fallback);
  }

  Widget _buildChatTileContent(
    BuildContext context,
    String displayName,
    String? displayImage,
    Group group,
  ) {
    final displayImageUrl = displayImage ?? '';
    return Consumer(
      builder: (context, ref, child) {
        final pinnedChats = ref.watch(pinnedChatsProvider);
        final pinnedChatsNotifier = ref.watch(pinnedChatsProvider.notifier);
        final isPinned = pinnedChats.contains(group.mlsGroupId);

        return Slidable(
          key: ValueKey(group.mlsGroupId),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 80.w / MediaQuery.of(context).size.width,
            children: [
              CustomSlidableAction(
                onPressed: (context) {
                  pinnedChatsNotifier.togglePin(group.mlsGroupId);
                },
                backgroundColor: context.colors.secondary,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  color: context.colors.secondary,
                  child: Center(
                    child: WnImage(
                      isPinned ? AssetsPaths.icUnpin : AssetsPaths.icPin,
                      size: 18.w,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                onTap!();
              }
              Routes.goToChat(context, group.mlsGroupId);
            },
            child: Container(
              padding: EdgeInsets.only(left: 8.w, right: 16.w, top: 12.h, bottom: 12.h),
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
                          item.lastMessage != null
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
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
          ),
        );
      },
    );
  }

  String _getMessagePreview(MessageModel message) {
    final content = message.content ?? '';

    if (message.isMe) {
      return 'chats.youMessage'.tr({'content': content});
    }
    return content;
  }
}

class ChatListTileLoading extends StatelessWidget {
  const ChatListTileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      child: Row(
        children: [
          WnSkeletonContainer(
            shape: BoxShape.circle,
            width: 56.w,
            height: 56.w,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WnSkeletonContainer(
                      width: 183.w,
                      height: 20.h,
                    ),
                    WnSkeletonContainer(
                      width: 30.w,
                      height: 20.h,
                    ),
                  ],
                ),
                Gap(6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    WnSkeletonContainer(
                      width: 244.w,
                      height: 32.h,
                    ),
                    WnSkeletonContainer(
                      width: 20.w,
                      height: 20.w,
                      shape: BoxShape.circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
