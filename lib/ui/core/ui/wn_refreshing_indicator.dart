import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnRefreshingIndicator extends StatelessWidget {
  const WnRefreshingIndicator({
    super.key,
    this.message,
    this.padding,
  });

  final String? message;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: 38.h),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16.w,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                  backgroundColor: context.colors.border,
                  strokeWidth: 3.w,
                ),
              ),
              Text(
                message ?? 'Loading...',
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          )
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .slideY(
            begin: -0.1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
    );
  }
}
