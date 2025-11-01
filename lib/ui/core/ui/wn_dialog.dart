import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? actions;
  final Widget? customChild;
  final Color? backgroundColor;

  const WnDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.backgroundColor,
  }) : customChild = null;

  const WnDialog.custom({
    super.key,
    required this.customChild,
    this.backgroundColor,
  }) : title = null,
       content = null,
       actions = null;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 15.0),
      child: Dialog(
        backgroundColor: backgroundColor ?? context.colors.neutral,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.r),
          side: BorderSide(
            color: context.colors.border,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child:
              customChild ??
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    content!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                  Gap(24.h),
                  actions!,
                ],
              ),
        ),
      ),
    );
  }
}
