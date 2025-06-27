import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/chat/widgets/status_message_item_widget.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ChatHeaderWidget extends StatelessWidget {
  final User contact;

  const ChatHeaderWidget({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          ChatContactAvatar(
            imgPath: contact.imagePath.orDefault,
            size: 96.r,
          ),

          Gap(12.h),
          Text(
            contact.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(12.h),
          Text(
            contact.nip05,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(8.h),
          Text(
            'Public Key: ${contact.publicKey.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'All messages are end-to-end encrypted. Only you and ${contact.name} can read them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
              ),
            ),
          ),
          Gap(24.h),
          StatusMessageItemWidget(
            icon: CarbonIcons.email,
            content: 'Chat invite sent to ${contact.name}',
            boldText: contact.name,
          ),
          Gap(12.h),
          StatusMessageItemWidget(
            icon: CarbonIcons.checkmark,
            content: '${contact.name} accepted the invite',
            boldText: contact.name,
          ),
          Gap(40.h),
        ],
      ),
    );
  }
}

extension StringExtension on String? {
  bool get nullOrEmpty => this?.isEmpty ?? true;
  // Returns a default image path if the string is null or empty
  String get orDefault => (this == null || this!.isEmpty) ? AssetsPaths.icImage : this!;
}
