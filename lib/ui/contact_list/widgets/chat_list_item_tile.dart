import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/contact_list/widgets/group_list_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/welcome_tile.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/utils/string_extensions.dart';
import 'package:whitenoise/utils/timeago_formatter.dart';

class ChatListItemTile extends ConsumerWidget {
  const ChatListItemTile({
    super.key,
    required this.item,
  });

  final ChatListItem item;

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
    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);
    final group = item.groupData!;

    // For DM chats, get the other member and use metadata cache for better user info
    if (group.groupType == GroupType.directMessage) {
      return FutureBuilder(
        future: ref.read(activeAccountProvider.notifier).getActiveAccountData(),
        builder: (context, accountSnapshot) {
          final activeAccountData = accountSnapshot.data;
          if (activeAccountData == null) {
            // Fallback to existing logic if no active account
            final currentUserNpub = ref.watch(nostrKeysProvider).npub ?? '';
            final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
            final displayImage = groupsNotifier.getGroupDisplayImage(
              group.mlsGroupId,
              currentUserNpub,
            );
            return _buildChatTileContent(context, displayName, displayImage, group);
          }

          final currentUserHexPubkey = activeAccountData.pubkey;
          final otherMember = groupsNotifier.getOtherGroupMember(
            group.mlsGroupId,
            currentUserHexPubkey,
          );

          if (otherMember != null) {
            return FutureBuilder(
              future: metadataCacheNotifier.getContactModel(otherMember.publicKey),
              builder: (context, snapshot) {
                final contactModel = snapshot.data;
                final displayName = contactModel?.displayNameOrName ?? otherMember.name;
                final displayImage = contactModel?.imagePath ?? (otherMember.imagePath ?? '');

                return _buildChatTileContent(context, displayName, displayImage, group);
              },
            );
          }

          // Fallback if no other member found
          final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
          final displayImage = groupsNotifier.getGroupDisplayImage(
            group.mlsGroupId,
            currentUserHexPubkey,
          );
          return _buildChatTileContent(context, displayName, displayImage, group);
        },
      );
    }

    // For regular groups, use existing logic
    final currentUserNpub = ref.watch(nostrKeysProvider).npub ?? '';
    final displayName = groupsNotifier.getGroupDisplayName(group.mlsGroupId) ?? group.name;
    final displayImage = groupsNotifier.getGroupDisplayImage(group.mlsGroupId, currentUserNpub);

    return _buildChatTileContent(context, displayName, displayImage, group);
  }

  Widget _buildChatTileContent(
    BuildContext context,
    String displayName,
    String? displayImage,
    GroupData group,
  ) {
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
                            item.lastMessage!.content ?? '',
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

}
