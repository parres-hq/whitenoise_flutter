import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WarningBox extends StatelessWidget {
  const WarningBox({
    super.key,
    required this.title,
    required this.description,
    this.colorTheme,
    this.iconPath,
    this.showBorder = true,
  });

  final String title;
  final String description;
  final Color? colorTheme;
  final String? iconPath;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final themeColor = colorTheme ?? context.colors.destructive;
    final icon = iconPath ?? AssetsPaths.icWarning;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        border: showBorder
            ? Border.all(
                color: themeColor,
                width: 1.w,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.w),
            child: WnImage(
              icon,
              size: 16.w,
              color: themeColor,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

