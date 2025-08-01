import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
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
      successMessage: 'Public Key copied.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContactAvatar(
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
              padding: EdgeInsets.all(8.sp),
              icon: Icon(
                CarbonIcons.copy,
                size: 24.sp,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
