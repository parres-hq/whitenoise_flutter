import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';

class ContactInfo extends StatelessWidget {
  final String? image;
  final String? title;
  final VoidCallback? onTap;
  final bool isLoading;

  const ContactInfo({
    super.key,
    required this.title,
    required this.image,
    this.onTap,
  }) : isLoading = false;

  const ContactInfo.loading({super.key})
    : image = null,
      title = null,
      onTap = null,
      isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: context.colors.mutedForeground.withValues(
                alpha: 0.2,
              ),
              shape: BoxShape.circle,
            ),
          ),
          Gap(8.w),
          Container(
            height: 16.h,
            constraints: BoxConstraints(maxWidth: 200.w, minWidth: 90.w),
            color: context.colors.mutedForeground.withValues(
              alpha: 0.2,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        WnAvatar(
          imageUrl: image!,
          displayName: title!,
          size: 36.r,
          showBorder: true,
        ),
        Gap(8.w),
        Text(
          title!,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.solidPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
