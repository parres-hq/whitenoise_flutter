import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ChatInputMediaSelector extends StatelessWidget {
  const ChatInputMediaSelector({
    super.key,
    required this.onImagesSelected,
  });

  final VoidCallback onImagesSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: context.colors.input,
            width: 1.w,
          ),
          right: BorderSide(
            color: context.colors.input,
            width: 1.w,
          ),
          bottom: BorderSide(
            color: context.colors.input,
            width: 1.w,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChatInputMediaSelectorOption(
            icon: AssetsPaths.icImage,
            label: 'chats.photos'.tr(),
            onTap: onImagesSelected,
          ),
          Divider(
            height: 1.h,
            thickness: 1.w,
            color: context.colors.input,
          ),
        ],
      ),
    );
  }
}

class _ChatInputMediaSelectorOption extends StatelessWidget {
  const _ChatInputMediaSelectorOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            WnImage(
              icon,
              size: 24.w,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
