import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WhitenoiseDialog extends StatelessWidget {
  final String title;
  final String content;
  final Widget actions;

  const WhitenoiseDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 15.0),
      child: Dialog(
        backgroundColor: context.colors.neutral,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.r),
          side: BorderSide(
            color: context.colors.border,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                content,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(24.h),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
