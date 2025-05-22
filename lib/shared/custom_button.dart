import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.buttonType = ButtonType.primary,
  });

  final void Function()? onPressed;
  final String title;
  final ButtonType buttonType;

  @override
  Widget build(BuildContext context) {
    final isPrimary = buttonType == ButtonType.primary;
    return SizedBox(
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
            borderRadius: BorderRadius.circular(0.r),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

enum ButtonType { primary, secondary }
