import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class UserProfile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String nip05;
  final String pubkey;
  final WidgetRef ref;

  const UserProfile({
    super.key,
    this.imageUrl = '',
    this.nip05 = '',
    required this.pubkey,
    required this.name,
    required this.ref,
  });

  void _copyToClipboard() {
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: pubkey,
      successMessage: 'chats.publicKeyCopied'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WnAvatar(
          imageUrl: imageUrl,
          displayName: name,
          size: 96.r,
          showBorder: imageUrl.isEmpty,
        ),
        Gap(8.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        if (nip05.isNotEmpty) ...[
          Gap(2.h),

          Text(
            nip05,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Gap(16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                pubkey.formatPublicKey(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: _copyToClipboard,
              padding: EdgeInsets.all(8.w),
              icon: WnImage(
                AssetsPaths.icCopy,
                size: 24.w,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
