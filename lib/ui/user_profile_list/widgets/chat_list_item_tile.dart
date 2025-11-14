import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/services/last_read_manager.dart';
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
import 'package:whitenoise/utils/pubkey_formatter.dart';
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
    final group = item.group;
    if (group == null) {
      return const SizedBox.shrink();
    }

    final watchedDisplayName = ref.watch(
      groupsProvider.select((s) => s.groupDisplayNames?[group.mlsGroupId]),
    );
    final watchedGroupImagePath = ref.watch(
      groupsProvider.select((s) => s.groupImagePaths?[group.mlsGroupId]),
    );

    if (watchedDisplayName == null) {
      return _buildChatTileLoading(context, group);
    }

    final groupType = ref.watch(
      groupsProvider.select((s) => s.groupTypes?[group.mlsGroupId]),
    );

    final String? avatarPubkey;
    if (groupType == GroupType.directMessage) {
      final members = ref.watch(
        groupsProvider.select((s) => s.groupMembers?[group.mlsGroupId]),
      );
      final activePubkey = ref.watch(activePubkeyProvider);
      final activePubkeyNpub =
          activePubkey != null ? PubkeyFormatter(pubkey: activePubkey).toNpub() : null;

      final otherMember = members?.firstWhereOrNull(
        (m) => m.publicKey != activePubkeyNpub,
      );
      avatarPubkey = otherMember?.publicKey;
    } else {
      avatarPubkey = group.nostrGroupId;
    }

    return _buildChatTileContent(
      context,
      watchedDisplayName,
      watchedGroupImagePath,
      group,
      avatarPubkey,
    );
  }

  Widget _buildChatTileLoading(BuildContext context, Group group) {
    return Consumer(
      builder: (context, ref, child) {
        final pinnedChats = ref.watch(pinnedChatsProvider);
        final pinnedChatsNotifier = ref.watch(pinnedChatsProvider.notifier);
        final isPinned = pinnedChats.contains(group.mlsGroupId);
        final chatState = ref.watch(chatProvider);
        final unreadCount = chatState.getUnreadCountForGroup(group.mlsGroupId);
        final hasMessages = chatState.areMessagesLoaded(group.mlsGroupId);
        final shouldShowMessageSkeleton = !hasMessages && group.lastMessageAt != null;

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
            onTap: () async {
              if (onTap != null) {
                onTap!();
              }
              if (item.lastMessage != null) {
                unawaited(
                  LastReadManager.saveLastReadImmediate(
                    group.mlsGroupId,
                    item.lastMessage!.createdAt,
                  ),
                );
                unawaited(ref.read(chatProvider.notifier).refreshUnreadCount(group.mlsGroupId));
              }
              if (!context.mounted) return;
              Routes.goToChat(context, group.mlsGroupId);
            },
            child: Container(
              padding: EdgeInsets.only(left: 8.w, right: 16.w, top: 12.h, bottom: 12.h),
              child: Row(
                children: [
                  WnSkeletonContainer(
                    shape: BoxShape.circle,
                    width: 56.r,
                    height: 56.r,
                  ),
                  Gap(8.w),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: WnSkeletonContainer(
                                width: 183.w,
                                height: 20.h,
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
                        Gap(4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          spacing: 32.w,
                          children: [
                            if (item.lastMessage != null)
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
                              )
                            else if (shouldShowMessageSkeleton)
                              Expanded(
                                child: WnSkeletonContainer(
                                  width: 244.w,
                                  height: 32.h,
                                ),
                              ),
                            if (item.lastMessage != null)
                              MessageReadStatus(
                                lastSentMessageStatus: item.lastMessage!.status,
                                unreadCount: unreadCount,
                              )
                            else if (shouldShowMessageSkeleton)
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTileContent(
    BuildContext context,
    String displayName,
    String? displayImage,
    Group group,
    String? pubkey,
  ) {
    final displayImageUrl = displayImage ?? '';
    return Consumer(
      builder: (context, ref, child) {
        final pinnedChats = ref.watch(pinnedChatsProvider);
        final pinnedChatsNotifier = ref.watch(pinnedChatsProvider.notifier);
        final isPinned = pinnedChats.contains(group.mlsGroupId);
        final chatState = ref.watch(chatProvider);
        final unreadCount = chatState.getUnreadCountForGroup(group.mlsGroupId);
        final hasMessages = chatState.areMessagesLoaded(group.mlsGroupId);
        final shouldShowMessageSkeleton = !hasMessages && group.lastMessageAt != null;

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
            onTap: () async {
              if (onTap != null) {
                onTap!();
              }
              if (item.lastMessage != null) {
                unawaited(
                  LastReadManager.saveLastReadImmediate(
                    group.mlsGroupId,
                    item.lastMessage!.createdAt,
                  ),
                );
                unawaited(ref.read(chatProvider.notifier).refreshUnreadCount(group.mlsGroupId));
              }
              if (!context.mounted) return;
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
                    pubkey: pubkey,
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
                            if (shouldShowMessageSkeleton)
                              WnSkeletonContainer(
                                width: 30.w,
                                height: 20.h,
                              )
                            else
                              Text(
                                item.lastMessage?.createdAt.timeago().capitalizeFirst ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                        if (shouldShowMessageSkeleton) ...[
                          Gap(4.h),
                          WnSkeletonContainer(
                            width: 244.w,
                            height: 32.h,
                          ),
                        ] else if (item.lastMessage != null) ...[
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
                              MessageReadStatus(
                                lastSentMessageStatus: item.lastMessage!.status,
                                unreadCount: unreadCount,
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
