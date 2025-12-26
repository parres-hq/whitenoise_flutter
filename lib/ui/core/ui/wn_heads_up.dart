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
    this.showCloseButton = false,
    this.onClose,
  });
  final String title;
  final String subtitle;
  final String? iconAsset;
  final Widget? action;
  final WnHeadingType type;
  final bool showCloseButton;
  final void Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final color = type.color(context);
    return Container(
      padding: showCloseButton ? EdgeInsets.fromLTRB(16.w, 6.w, 16.w, 14.w) : EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: color,
            width: 1.w,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              WnImage(
                iconAsset ?? type.iconAsset,
                width: 18.w,
                height: 18.w,
                color: color,
              ),
              Gap(8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              if (showCloseButton) ...[
                Gap(8.w),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: WnImage(
                      AssetsPaths.icClose,
                      width: 16.w,
                      height: 16.w,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Gap(2.w),
          Row(
            children: [
              Gap(26.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                    if (action != null) ...[
                      Gap(4.h),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum WnHeadingType {
  error,
  warning,
  info,
  infoBlack;

  Color color(BuildContext context) {
    switch (this) {
      case WnHeadingType.error:
        return context.colors.destructive;
      case WnHeadingType.warning:
        return context.colors.warning;
      case WnHeadingType.info:
        return context.colors.info;
      case WnHeadingType.infoBlack:
        return context.colors.primary;
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
      case WnHeadingType.infoBlack:
        return AssetsPaths.icInfoFilled;
    }
  }
}
