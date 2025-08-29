import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnHeadsUp extends StatelessWidget {
  const WnHeadsUp({
    super.key,
    required this.title,
    required this.subtitle,
    this.type = WnHeadingType.error,
    this.iconAsset,
    this.action,
  });
  final String title;
  final String subtitle;
  final String? iconAsset;
  final Widget? action;
  final WnHeadingType type;

  @override
  Widget build(BuildContext context) {
    final color = type.color(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: color,
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WnImage(
            iconAsset ?? type.iconAsset,
            width: 24.w,
            height: 24.w,
            color: color,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                Gap(4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(4.h),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum WnHeadingType {
  error,
  warning,
  info;

  Color color(BuildContext context) {
    switch (this) {
      case WnHeadingType.error:
        return context.colors.destructive;
      case WnHeadingType.warning:
        return context.colors.warning;
      case WnHeadingType.info:
        return context.colors.info;
    }
  }

  String get iconAsset {
    switch (this) {
      case WnHeadingType.error:
        return AssetsPaths.icErrorFilled;
      case WnHeadingType.warning:
        return AssetsPaths.icWarningFilled;
      case WnHeadingType.info:
        return AssetsPaths.icInformation;
    }
  }
}
