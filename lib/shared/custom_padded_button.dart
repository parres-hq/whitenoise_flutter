import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

/// A custom button with the new design pattern:
/// - Horizontal padding from screen edges
/// - Bottom padding so it's not pinned to the bottom
/// - Rounded corners
/// - Full width within padding constraints
class CustomPaddedButton extends StatelessWidget {
  const CustomPaddedButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.buttonType = ButtonType.primary,
    this.horizontalPadding = 24.0,
    this.bottomPadding = 24.0,
    this.borderRadius = 8.0,
  });

  final void Function()? onPressed;
  final String title;
  final ButtonType buttonType;
  final double horizontalPadding;
  final double bottomPadding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isPrimary = buttonType == ButtonType.primary;
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding.w,
        right: horizontalPadding.w,
        bottom: bottomPadding.h,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor:
                isPrimary ? AppColors.glitch950 : AppColors.glitch100,
            foregroundColor: isPrimary ? AppColors.glitch50 : AppColors.glitch900,
            disabledBackgroundColor:
                isPrimary
                    ? AppColors.glitch950.withValues(alpha: 0.5)
                    : AppColors.glitch100,
            disabledForegroundColor:
                isPrimary ? AppColors.glitch50 : AppColors.glitch900,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.r),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

enum ButtonType { primary, secondary }