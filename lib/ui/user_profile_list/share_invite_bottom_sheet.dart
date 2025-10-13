import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/share_invite_button.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/share_invite_callout.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/user_profile_card.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/user_profile_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ShareInviteBottomSheet extends ConsumerStatefulWidget {
  final List<UserProfile> userProfiles;

  const ShareInviteBottomSheet({
    super.key,
    required this.userProfiles,
  });

  static Future<void> show({
    required BuildContext context,
    required List<UserProfile> userProfiles,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'ui.inviteToChat'.tr(),
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => ShareInviteBottomSheet(userProfiles: userProfiles),
    );
  }

  @override
  ConsumerState<ShareInviteBottomSheet> createState() => _ShareInviteBottomSheetState();
}

class _ShareInviteBottomSheetState extends ConsumerState<ShareInviteBottomSheet> {
  @override
  Widget build(BuildContext context) {
    if (widget.userProfiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final isSingleUserProfile = widget.userProfiles.length == 1;
    final singleUserProfile = widget.userProfiles.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSingleUserProfile) ...[
          Gap(12.h),
          UserProfileCard(
            imageUrl: singleUserProfile.imagePath ?? '',
            name: singleUserProfile.displayName,
            nip05: singleUserProfile.nip05 ?? '',
            pubkey: singleUserProfile.publicKey,
            ref: ref,
          ),
          Gap(36.h),
          ShareInviteCallout(userProfile: singleUserProfile),
        ] else ...[
          // Multiple userProfiles view
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Gap(24.h),
                WnCallout(
                  title: 'ui.inviteToWhiteNoise'.tr(),
                  description: 'ui.usersNotReadyForSecureMessaging'.tr(),
                ),
                Gap(16.h),
              ],
            ),
          ),

          ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shrinkWrap: true,
            primary: false,
            itemCount: widget.userProfiles.length,
            itemBuilder: (context, index) {
              final userProfile = widget.userProfiles[index];
              return UserProfileTile(userProfile: userProfile);
            },
          ),
        ],
        Gap(14.h),
        const ShareInviteButton(),
      ],
    );
  }
}
