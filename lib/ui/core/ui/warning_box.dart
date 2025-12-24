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
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
  });

  final String title;
  final String description;
  final Color? colorTheme;
  final String? iconPath;
  final bool showBorder;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;

  @override
  Widget build(BuildContext context) {
    final themeColor = colorTheme ?? context.colors.destructive;
    final icon = iconPath ?? AssetsPaths.icWarning;
    final bgColor = backgroundColor ?? themeColor.withValues(alpha: 0.1);
    final border = borderColor ?? themeColor;
    final iconCol = iconColor ?? themeColor;
    final titleCol = titleColor ?? context.colors.primary;
    final descCol = descriptionColor ?? context.colors.primary;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor,
        border:
            showBorder
                ? Border.all(
                  color: border,
                  width: 1.w,
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.w),
                child: WnImage(
                  icon,
                  size: 16.w,
                  color: iconCol,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: titleCol,
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: descCol,
            ),
          ),
        ],
      ),
    );
  }
}
