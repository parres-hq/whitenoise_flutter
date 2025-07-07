import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ContactInfo extends StatelessWidget {
  final String imageUrl;
  final String title;
  const ContactInfo({super.key, required this.title, required this.imageUrl, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          ContactAvatar(
            imageUrl: imageUrl,
            displayName: title,
            size: 36.r,
            showBorder: true,
          ),
          Gap(8.w),
          Text(
            title,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.solidPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
