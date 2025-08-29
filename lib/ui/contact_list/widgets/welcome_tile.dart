import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/string_extensions.dart';
import 'package:whitenoise/utils/timeago_formatter.dart';

class WelcomeTile extends ConsumerWidget {
  const WelcomeTile({
    super.key,
    required this.item,
  });

  final ChatListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welcome = item.welcome;
    if (welcome == null) {
      return const SizedBox.shrink();
    }

    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);

    return FutureBuilder(
      future: metadataCacheNotifier.getContactModel(welcome.welcomer),
      builder: (context, snapshot) {
        final welcomerContact = snapshot.data;
        final welcomerName = welcomerContact?.displayName ?? 'Unknown User';
        final welcomerImageUrl = welcomerContact?.imagePath ?? '';

        return InkWell(
          onTap: () => Routes.goToChat(context, welcome.mlsGroupId, inviteId: welcome.id),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                WnAvatar(
                  imageUrl: welcomerImageUrl,
                  displayName: welcomerName,
                  size: 56.r,
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
                            child: Text(
                              welcomerName,
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
                            item.dateCreated.timeago().capitalizeFirst,
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
                          Expanded(
                            child: Text(
                              'invited you to ${welcome.groupName}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.colors.mutedForeground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          WnImage(
                            AssetsPaths.icChatInvite,
                            size: 16.w,
                            color: context.colors.mutedForeground,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
