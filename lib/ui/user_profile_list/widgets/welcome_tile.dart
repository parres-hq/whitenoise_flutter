import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_skeleton_container.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
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

    // Watch cached welcomer user data from welcomes provider
    final welcomerUser = ref.watch(
      welcomesProvider.select((s) => s.welcomerUsers?[welcome.welcomer]),
    );

    // Show partial loading tile with timestamp and invitation text immediately available
    if (welcomerUser == null) {
      return _buildWelcomeTileLoading(context, welcome);
    }
    final welcomerNpub = PubkeyFormatter(pubkey: welcome.welcomer).toNpub();

    return InkWell(
      onTap: () => Routes.goToChat(context, welcome.mlsGroupId, inviteId: welcome.id),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            WnAvatar(
              imageUrl: welcomerUser.imagePath ?? '',
              displayName: welcomerUser.displayName,
              pubkey: welcomerNpub,
              showBorder: true,
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
                          welcomerUser.displayName,
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
                          welcome.groupName.isEmpty
                              ? 'chats.secureInvitationSent'.tr()
                              : 'chats.invitedToGroup'.tr({'groupName': welcome.groupName}),
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
  }

  Widget _buildWelcomeTileLoading(BuildContext context, Welcome welcome) {
    return InkWell(
      onTap: () => Routes.goToChat(context, welcome.mlsGroupId, inviteId: welcome.id),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            // Show skeleton avatar while welcomer data is loading
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
                      // Show skeleton display name while welcomer data is loading
                      Expanded(
                        child: WnSkeletonContainer(
                          width: 100.w,
                          height: 20.h,
                        ),
                      ),
                      // Show actual timestamp immediately
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
                      // Show actual invitation text immediately
                      Expanded(
                        child: Text(
                          welcome.groupName.isEmpty
                              ? 'chats.secureInvitationSent'.tr()
                              : 'chats.invitedToGroup'.tr({'groupName': welcome.groupName}),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: context.colors.mutedForeground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Show actual invite icon immediately
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
  }
}
