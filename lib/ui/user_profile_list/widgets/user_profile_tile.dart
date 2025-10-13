import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_skeleton_container.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class UserProfileTile extends StatelessWidget {
  final UserProfile userProfile;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showCheck;
  final bool showExpansionArrow;
  final Widget? trailingIcon;
  final String? preformattedPublicKey;

  const UserProfileTile({
    required this.userProfile,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showCheck = false,
    this.showExpansionArrow = false,
    this.trailingIcon,
    this.preformattedPublicKey,
    super.key,
  });

  String _getFormattedPublicKey() {
    if (preformattedPublicKey != null && preformattedPublicKey!.isNotEmpty) {
      return preformattedPublicKey!;
    }

    try {
      final npub = PubkeyFormatter(pubkey: userProfile.publicKey).toNpub() ?? '';
      return npub.formatPublicKey();
    } catch (e) {
      // Return the full hex key as fallback
      return userProfile.publicKey.formatPublicKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileImagePath = userProfile.imagePath ?? '';
    final formattedKey = _getFormattedPublicKey();

    final userProfileTile = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            WnAvatar(
              imageUrl: userProfileImagePath,
              displayName: userProfile.displayName,
              size: 56.w,
              showBorder: userProfileImagePath.isEmpty,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userProfile.displayName,
                          style: TextStyle(
                            color: context.colors.secondaryForeground,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Gap(2.h),
                  Text(
                    formattedKey,
                    style: TextStyle(
                      color: context.colors.mutedForeground,
                      fontSize: 12.sp,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (showCheck) ...[
              Gap(16.w),
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? context.colors.primary : context.colors.baseMuted,
                    width: 1.5.w,
                  ),
                  color: isSelected ? context.colors.primary : Colors.transparent,
                ),
                child:
                    isSelected
                        ? WnImage(
                          AssetsPaths.icCheckmark,
                          size: 16.w,
                          color: context.colors.primaryForeground,
                        )
                        : null,
              ),
            ] else if (trailingIcon != null) ...[
              Gap(16.w),
              trailingIcon!,
            ] else if (showExpansionArrow) ...[
              Gap(16.w),
              WnImage(AssetsPaths.icExpand, width: 11.w, height: 18.w),
            ],
          ],
        ),
      ),
    );

    return userProfileTile;
  }
}

class UserProfileTileLoading extends StatelessWidget {
  const UserProfileTileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          WnSkeletonContainer(
            shape: BoxShape.circle,
            width: 56.w,
            height: 56.w,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WnSkeletonContainer(
                  width: 183.w,
                  height: 20.h,
                ),
                Gap(6.h),
                WnSkeletonContainer(
                  width: 1.sw,
                  height: 32.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
