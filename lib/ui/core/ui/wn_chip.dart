import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnChip extends StatelessWidget {
  const WnChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.avatarUrl,
  });

  final String label;
  final String? avatarUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ContactAvatar(
            imageUrl: avatarUrl ?? '',
            displayName: label,
            size: 18.r,
          ),
          Gap(8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primaryForeground,
            ),
          ),
          Gap(8.w),
          InkWell(
            onTap: onRemove,
            child: Icon(
              CarbonIcons.close,
              size: 16.r,
              color: context.colors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}
