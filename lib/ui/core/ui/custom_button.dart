import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.buttonType = ButtonType.primary,
    this.addPadding = true,
    this.horizontalPadding = 24.0,
    this.bottomPadding = 24.0,
  });

  final void Function()? onPressed;
  final String title;
  final ButtonType buttonType;
  final bool addPadding;
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isPrimary = buttonType == ButtonType.primary;
    final button = SizedBox(
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
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );

    if (addPadding) {
      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding.w,
          right: horizontalPadding.w,
          bottom: bottomPadding.h,
        ),
        child: button,
      );
    }
    return button;
  }
}

enum ButtonType { primary, secondary }